# frozen_string_literal: true

require_relative 'parquet_source'
require_relative 'sgeo_decoder'
require_relative 'vocab'

module SpeckleConnector3
  module Artifacts
    # Reads a 4.0 artefact bundle back into a plain structured model — the inverse of
    # the producer, with NO SketchUp dependency (unit-testable headless).
    #
    # Notably it resolves each object's **scene_path**: the ordered tag/folder labels
    # the receive should organise it under, driven by the producer's DEFAULT
    # `envelope.scene_views` projection. So a SketchUp bundle (IN_COLLECTION tier ->
    # the tag-folder tree) and a Revit bundle (ON_LEVEL -> category -> family tiers)
    # both come back organised, instead of dumping at the model root.
    #
    # Returns a Hash with: collections, materials, colors, definitions, instances,
    # geometries, material_by_geom, default_scene_view, and objects (each with
    # :app_id, :scene_path [String...], :color_argb, :is_soften, :properties,
    # :displays [geom_k...], :display_instances [inst_node_k...]).
    module BundleReader
      # Pre-v5 vocabulary, accepted on read only: kind 6 COLLECTION (folded into
      # CONTAINER + `subtype` in v5) and the retired membership rels 13, 15-20, 22.
      LEGACY_COLLECTION_KIND = 6
      DEFINITION_PROXY_TYPE = 'Speckle.Core.Models.Instances.InstanceDefinitionProxy'
      INSTANCE_PROXY_TYPE = 'Speckle.Core.Models.Instances.InstanceProxy'
      MEMBERSHIP_RELS = [
        RelKind::ON_LEVEL, RelKind::IN_COLLECTION, RelKind::IN_MODEL, RelKind::IN_ROOM,
        RelKind::IN_SYSTEM, 13, 15, 16, 17, 18, 19, 20, 22
      ].freeze

      module_function

      def read(dir, base)
        env = ->(t) { ParquetSource.read_hashes(File.join(dir, "#{base}.envelope.#{t}.parquet")) }
        eav = ->(t) { ParquetSource.read_hashes(File.join(dir, "#{base}.eav.#{t}.parquet")) }

        nodes = index_by(env.call('nodes'), 'id')
        relations = env.call('relations')
        object_app = eav.call('objects').to_h { |r| [r['object_index'], r['application_id']] }
        paths = eav.call('paths').to_h { |r| [r['path_index'], r['path']] }
        props_by_obj = group_eav(eav.call('eav'), paths)
        props_by_type = group_eav(read_optional(dir, "#{base}.eav.type_eav.parquet"), paths, key: 'type_index')
        geometries = read_geometries(dir, base)
        default_view = read_default_scene_view(dir, base)

        model = {
          collections: {}, materials: {}, colors: {}, definitions: {}, instances: {},
          node_meta: {}, geometries: geometries, objects: [], material_by_geom: {},
          member_tag_paths: {},
          default_scene_view: default_view, definition_meta: definition_meta(props_by_obj, props_by_type),
          instance_meta: instance_meta(props_by_obj),
          levels: {}, units: producer_units(props_by_obj),
          produced_by: read_produced_by(env),
          camera_views: read_camera_views(dir, base)
        }
        classify_nodes(nodes, model)
        wire_relations(relations, model, object_app, props_by_obj, default_view)
        model
      end

      # Definition-level metadata (ENG-8842): a type_eav row-set keyed by the
      # definition's persistent id (its type_key) — a definition is a TYPE, not
      # an interactable scene object, so it never appears in the objects table.
      # Bundles from before the type split carried the same row-set in eav as a
      # pseudo-object; both sources are scanned (legacy first, so type rows win)
      # and old already-published models keep receiving. Joined back by the
      # DEFINITION node's dense id (the producer stamps it as
      # `@speckle.definition_k`); bundles from before that stamp fall back to
      # the name join (unique in SketchUp).
      # Returns {node_k | name -> {description, dictionaries}}.
      def definition_meta(props_by_obj, props_by_type = {})
        meta = {}
        [props_by_obj, props_by_type].each do |source|
          source.each_value do |props|
            next unless props['speckle_type'] == DEFINITION_PROXY_TYPE

            entry = { description: props['description'], dictionaries: unflatten_dictionaries(props) }
            def_k = props['@speckle.definition_k']
            name = props['name']
            meta[def_k.to_i] = entry unless def_k.nil?
            meta[name] = entry unless name.nil? || name.to_s.empty?
          end
        end
        meta
      end

      # Nested-instance metadata: eav row-sets stamped with `@speckle.instance_k`
      # (the INSTANCE node's dense id). Top-level instances carry their properties
      # on the scene object itself and are not stamped, so they don't appear here.
      # Returns instance node k -> {name, dictionaries}.
      def instance_meta(props_by_obj)
        meta = {}
        props_by_obj.each_value do |props|
          inst_k = props['@speckle.instance_k']
          next if inst_k.nil? || props['speckle_type'] != INSTANCE_PROXY_TYPE

          meta[inst_k.to_i] = { name: props['name'], dictionaries: unflatten_dictionaries(props) }
        end
        meta
      end

      # The envelope meta's producer stamp (e.g. 'speckle-sketchup EnvelopeWriter',
      # 'Speckle.Sdk EnvelopeWriter') — lets receive vary host behaviour by source.
      def read_produced_by(env)
        (env.call('meta').first || {})['produced_by']
      rescue StandardError
        nil
      end

      # The producer's model units, read off any object's `units` root scalar
      # (every object carries one). LEVEL node elevations are in these units.
      def producer_units(props_by_obj)
        props_by_obj.each_value do |props|
          units = props['units']
          return units unless units.nil? || units.to_s.empty?
        end
        nil
      end

      # Rebuilds nested attribute dictionaries from the flattened dotted eav paths
      # ('properties.Dict.key' -> {'Dict' => {'key' => value}}).
      def unflatten_dictionaries(props)
        dicts = {}
        props.each do |path, value|
          next unless path.start_with?('properties.')

          segments = path.split('.')[1..]
          next if segments.empty?

          cursor = dicts
          segments[0..-2].each { |seg| cursor = (cursor[seg] = cursor[seg].is_a?(Hash) ? cursor[seg] : {}) }
          cursor[segments.last] = value
        end
        dicts
      end

      # ── nodes ─────────────────────────────────────────────────────────

      def classify_nodes(nodes, model)
        nodes.each do |id, n|
          case n['kind']
          when NodeKind::CONTAINER, LEGACY_COLLECTION_KIND
            # v5 bundles carry the discriminator in `subtype`; pre-v5 overloaded `units`.
            model[:collections][id] = {
              name: n['name'], parent_k: n['def_ref'], subtype: n['subtype'] || n['units'], argb: n['argb']
            }
            model[:node_meta][id] = { name: n['name'], parent_k: n['def_ref'] } # tag/folder/model tier
          when NodeKind::LEVEL
            model[:node_meta][id] = { name: n['name'], parent_k: nil }
            model[:levels][id] = { name: n['name'], elevation: n['elevation'] }
          when NodeKind::MATERIAL
            model[:materials][id] = {
              name: n['name'],
              argb: n['argb'], opacity: n['opacity'], metalness: n['metalness'], roughness: n['roughness']
            }
          when NodeKind::COLOR
            model[:colors][id] = n['argb']
          when NodeKind::DEFINITION
            model[:definitions][id] = { name: n['name'], geometry_ks: [], instance_ks: [] }
          when NodeKind::INSTANCE
            model[:instances][id] = {
              def_ref: n['def_ref'], transform: parse_transform(n['transform']), units: n['units']
            }
          end
        end
      end

      # ── relations ─────────────────────────────────────────────────────

      def wire_relations(relations, model, object_app, props_by_obj, default_view)
        objects = {}
        memberships = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } } # oi -> rel -> [node]
        obj = lambda do |oi|
          objects[oi] ||= begin
            props = props_by_obj[oi] || {}
            {
              app_id: object_app[oi], color_argb: nil, is_soften: props['@speckle.is_soften'],
              properties: props, displays: [], display_instances: [], scene_path: []
            }
          end
        end

        relations.each do |r|
          rel = r['rel']
          src = r['src']
          dst = r['dst']
          memberships[src][rel] << dst
          case rel
          when RelKind::DISPLAY then obj.call(src)[:displays] << dst
          when RelKind::DISPLAY_INSTANCE then obj.call(src)[:display_instances] << dst
          when RelKind::HAS_COLOR then obj.call(src)[:color_argb] = model[:colors][dst]
          when RelKind::HAS_MATERIAL then model[:material_by_geom][src] = dst
          when RelKind::DEFINES then model[:definitions][src][:geometry_ks] << dst if model[:definitions][src]
          when RelKind::DEFINES_INSTANCE then model[:definitions][src][:instance_ks] << dst if model[:definitions][src]
          else
            obj.call(src) if MEMBERSHIP_RELS.include?(rel) # ensure membership-only objects exist
          end
        end

        objects.each do |oi, object|
          object[:scene_path] = scene_path_for(oi, default_view, memberships, model[:node_meta], props_by_obj[oi] || {})
        end
        # Definition-member carrier objects are template metadata, not scene
        # objects (ENG-8851): a `@speckle.instance_k` stamp hands the tag path to
        # instance_meta (nested instances), a `@speckle.geometry_k` stamp to
        # member_tag_paths (member meshes/edges) — and both stay out of
        # model[:objects].
        objects.reject! do |oi, object|
          props = props_by_obj[oi] || {}
          inst_k = props['@speckle.instance_k']
          geom_k = props['@speckle.geometry_k']
          if !inst_k.nil?
            meta = (model[:instance_meta][inst_k.to_i] ||= {})
            meta[:scene_path] = object[:scene_path] unless object[:scene_path].empty?
            true
          elsif !geom_k.nil?
            model[:member_tag_paths][geom_k.to_i] = object[:scene_path] unless object[:scene_path].empty?
            true
          else
            false
          end
        end
        model[:objects] = objects.values
      end

      # The ordered tag/folder labels for an object, from the default scene view.
      def scene_path_for(object_index, default_view, memberships, node_meta, props)
        segments = []
        default_view.each do |key|
          if key[:source] == 'rel'
            rel = key[:ref].to_i
            memberships[object_index][rel].each { |node_k| segments.concat(label_chain(node_k, node_meta)) }
          else # eav group-by
            value = props[key[:ref]]
            segments << value.to_s unless value.nil? || value.to_s.empty?
          end
        end
        segments
      end

      # Walks a node's parent chain (root-first) into its label segments.
      def label_chain(node_k, node_meta)
        chain = []
        cur = node_k
        guard = 0
        while cur && (meta = node_meta[cur]) && guard < 64
          chain.unshift(meta[:name]) unless meta[:name].nil? || meta[:name].empty?
          cur = meta[:parent_k]
          guard += 1
        end
        chain
      end

      # ── helpers ───────────────────────────────────────────────────────

      def read_default_scene_view(dir, base)
        path = File.join(dir, "#{base}.envelope.scene_views.parquet")
        return [] unless File.exist?(path)

        rows = ParquetSource.read_hashes(path)
        by_view = rows.group_by { |r| r['view'] }
        chosen = by_view.values.find { |vr| vr.any? { |r| r['is_default'] } } || by_view.values.first || []
        chosen.sort_by { |r| r['ord'] }.map { |r| { source: r['source'], ref: r['ref'] } }
      end

      # Optional `{base}.envelope.camera_views.parquet` (named viewpoints) — an
      # absent file means the producer shipped none. Rows in scene-tab order.
      def read_camera_views(dir, base)
        path = File.join(dir, "#{base}.envelope.camera_views.parquet")
        return [] unless File.exist?(path)

        ParquetSource.read_hashes(path).sort_by { |r| [r['ord'] || 0, r['view'] || 0] }
      rescue StandardError => e
        puts "Speckle: could not read camera_views (#{e.message})"
        []
      end

      def read_geometries(dir, base)
        geom = {}
        skipped = Hash.new(0)
        # No Dir.glob here: `base` is producer-chosen (a file importer uses the source
        # file's stem — see ENG-8945) and may contain glob metacharacters like `[`.
        shards = Dir.children(dir)
                    .select { |n| n.start_with?("#{base}.geometries") && n.end_with?('.parquet') }
                    .sort.map { |n| File.join(dir, n) }
        shards.each do |path|
          ParquetSource.read_hashes(path).each do |row|
            content = row['content']
            # The geometries file can carry non-SGEO blobs alongside SGEO — e.g. a Rhino
            # bundle stores each solid's raw ".3dm" under the SOLID relation ("3D Geometry
            # File Format…" magic). SketchUp consumes only the SGEO display geometry (those
            # solids also emit SGEO display meshes), so skip anything without the SGEO magic
            # instead of erroring on the first foreign blob.
            if content.nil? || content.b.byteslice(0, 4) != SgeoEncoder::MAGIC
              skipped[row['type']] += 1
              next
            end
            geom[row['geometryIndex']] = SgeoDecoder.decode(content)
          end
        end
        unless skipped.empty?
          warn("Speckle: skipped #{skipped.values.sum} non-SGEO geometry blob(s) " \
               "(#{skipped.map { |t, c| "#{t}:#{c}" }.join(', ')})")
        end
        geom
      end

      # Metadata scalars that must round-trip as authored strings: the producer's
      # type inference stores numeric-looking strings ("1000") typed for querying
      # (value_double), but the native side needs the string form back — a Float
      # description/name crashes the SketchUp setters.
      STRING_PATHS = %w[name description speckle_type units layer].freeze

      # SketchUp's advanced-attribute dictionaries (Price/Size/Url on the
      # definition, Owner/Status on the instance) are string-typed: the panel
      # silently ignores non-String values, so a Price authored as "1" must come
      # back as the authored "1", not the query-typed 1.0.
      STRING_DICT_PREFIXES = %w[properties.SU_DefinitionSet. properties.SU_InstanceSet.].freeze

      def group_eav(rows, paths, key: 'object_index')
        by_key = Hash.new { |h, k| h[k] = {} }
        rows.each do |row|
          path = paths[row['path_index']]
          by_key[row[key]][path] = string_typed?(path) ? string_value(row) : eav_value(row)
        end
        by_key
      end

      def string_typed?(path)
        STRING_PATHS.include?(path) || STRING_DICT_PREFIXES.any? { |prefix| path.to_s.start_with?(prefix) }
      end

      # Reads an eav table a foreign producer may not ship (e.g. type_eav) —
      # an absent file is an empty table, not an error.
      def read_optional(dir, filename)
        path = File.join(dir, filename)
        File.exist?(path) ? ParquetSource.read_hashes(path) : []
      end

      def eav_value(row)
        return row['value_boolean'] unless row['value_boolean'].nil?
        return row['value_double'] unless row['value_double'].nil?

        row['value_string']
      end

      def string_value(row)
        row['value_string'] || eav_value(row)&.to_s
      end

      def parse_transform(str)
        return nil if str.nil?

        str.split(',').map(&:to_f)
      end

      def index_by(rows, key)
        rows.to_h { |r| [r[key], r] }
      end
    end
  end
end
