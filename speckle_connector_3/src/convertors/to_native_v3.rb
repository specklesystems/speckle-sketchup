# frozen_string_literal: true

require_relative '../artifacts/bundle_reader'
require_relative '../artifacts/op_stats'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/geometry/length'
require_relative '../constants/pref_constants'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/color'
require_relative '../sketchup_model/dictionary/base_dictionary_handler'

module SpeckleConnector3
  module Converters
    # Speckle 4.0 receive: rebuilds native SketchUp entities from a parquet artefact
    # bundle. The data reconstruction ({Artifacts::BundleReader}) is host-independent
    # and unit-tested headless; this class is the SketchUp-API layer that turns the
    # reconstructed model into tags, meshes, components, instances, and materials.
    #
    # Mirror of {ToSpeckleV3}; reuses the existing native primitives
    # (Point.to_native / Transform.to_native / Color.from_int / add_faces_from_mesh).
    class ToNativeV3
      POINT = SpeckleConnector3::SpeckleObjects::Geometry::Point
      TRANSFORM = SpeckleConnector3::SpeckleObjects::Other::Transform
      COLOR = SpeckleConnector3::SpeckleObjects::Other::Color
      DICT = SpeckleConnector3::SketchupModel::Dictionary::BaseDictionaryHandler

      # @return [Array<Sketchup::Entity>] top-level entities created this receive
      attr_reader :created_top_level

      # @return [Array<Sketchup::Face>] every face baked this receive (top-level and
      # inside definitions) — the input for the post-receive coplanar merge (v2 parity)
      attr_reader :converted_faces

      # @return [Artifacts::OpStats] per-phase timings/counters for this receive
      attr_reader :stats

      # Display name for the wrapping component (set from the receive card's
      # project/model names); receives are wrapped so multiple received models
      # stay distinguishable in the same SketchUp file.
      attr_accessor :wrap_name

      # Stable identity of the receive card ("<projectId>/<modelId>"). Baked
      # top-level entities are stamped with it so the card's next receive can
      # erase its previous bake (ENG-8850); nil/empty skips both stamp and erase.
      attr_accessor :receive_key

      # Attribute dictionary carrying the receive stamp.
      STAMP_DICT = 'Speckle_Receive'

      # @param sketchup_model [Sketchup::Model]
      # @param stats [Artifacts::OpStats, nil] shared stats collector (one is
      #   created when not provided, so headless/test callers stay unchanged)
      def initialize(sketchup_model, stats = nil)
        @model = sketchup_model
        @stats = stats || Artifacts::OpStats.new('receive')
        @folder_by_path = {}
        @tag_by_path = {}
        @used_tag_names = {}
        @uniq_counter = 0
        @material_by_k = {}
        @definition_by_k = {}
        @created_top_level = []
        @converted_faces = []
        @tag_color_by_path = {}
        @wrap_definition = nil
        @wrap_instance = nil
        @claimed_definition_ids = {}
      end

      # Reads a bundle from `dir` (base name `base`) and builds it into the model.
      # @return [Integer] number of top-level objects created
      def receive(dir, base)
        model = @stats.time(:bundle_read) { Artifacts::BundleReader.read(dir, base) }
        build(model)
      end

      # @return [Array<String>] persistent ids for highlight — the wrapping
      # component instance when present (selecting it selects the whole received
      # model), else the created top-level entities.
      def created_top_level_ids
        return [@wrap_instance.persistent_id.to_s] if @wrap_instance && !@wrap_instance.deleted?

        @created_top_level.reject(&:deleted?).map { |e| e.persistent_id.to_s }
      end

      # @param model [Hash] the reconstructed model from {Artifacts::BundleReader}
      def build(model)
        @tag_color_by_path = tag_colors_by_path(model)
        # v2 parity: SketchUp-sourced models bake directly into the model (their
        # own grouping/tags already structure them); only foreign models get the
        # wrapper component. The bundle's meta stamp identifies the producer.
        if model[:produced_by].to_s.match?(/sketchup/i)
          # Loose bakes are stamped per receive card; erase the card's previous
          # bake before rebuilding (ENG-8850).
          @stats.time(:erase_previous) { erase_previous_bake }
          @target = @model.entities
        else
          # Reuse-and-clear the same-named wrap definition (v2's
          # project-model-definition pattern), keeping its placed instance so a
          # user-moved received model stays where they put it.
          @wrap_definition = claim_definition(wrap_name.to_s.empty? ? 'Speckle Model' : wrap_name)
          @wrap_instance = @wrap_definition.instances.find { |i| !i.deleted? }
          @stats.time(:erase_previous) { erase_previous_bake(keep: @wrap_instance) }
          @target = @wrap_definition.entities
        end
        @stats.time(:materials) { build_materials(model[:materials]) }
        @stats.time(:definitions) { build_definitions(model) }
        @stats.time(:objects) { model[:objects].each { |obj| build_object(model, obj) } }
        @stats.time(:levels) { build_levels(model) }
        @stats.time(:camera_views) { build_camera_views(model) }
        # The wrapper is filled first, then placed once at the origin (v2's
        # project-model-definition pattern).
        if @wrap_definition
          @wrap_instance ||= @model.entities.add_instance(@wrap_definition, Geom::Transformation.new)
          stamp(@wrap_instance, 'wrap')
        else
          @created_top_level.each { |e| stamp(e, 'loose') }
        end
        @stats.add(:objects, model[:objects].length)
        model[:objects].length
      end

      private

      # ── re-receive: erase previous bake (ENG-8850) ────────────────────

      def stamp(entity, kind)
        return if receive_key.to_s.empty? || entity.nil? || entity.deleted?

        entity.set_attribute(STAMP_DICT, 'receive_key', receive_key)
        entity.set_attribute(STAMP_DICT, 'kind', kind)
      end

      # Erases every top-level entity this receive card baked previously (its
      # stamp matches `receive_key`), except `keep` (the reused wrap instance).
      # Stamped faces pull their boundary edges along when no surviving face
      # still uses them (loose meshes only track faces; edges are implicit).
      # A stale wrap instance under a different definition (project/model was
      # renamed) also drops its now-orphaned definition.
      def erase_previous_bake(keep: nil)
        return if receive_key.to_s.empty?

        stale = @model.entities.select do |e|
          !e.deleted? && !e.equal?(keep) && e.get_attribute(STAMP_DICT, 'receive_key') == receive_key
        end
        return if stale.empty?

        faces = stale.grep(Sketchup::Face)
        stale_face_ids = {}
        faces.each { |f| stale_face_ids[f.entityID] = true }
        orphan_edges = faces.flat_map(&:edges).uniq.select do |edge|
          edge.faces.all? { |f| stale_face_ids.key?(f.entityID) }
        end
        orphan_definitions = stale
                             .select { |e| e.is_a?(Sketchup::ComponentInstance) && e.get_attribute(STAMP_DICT, 'kind') == 'wrap' }
                             .map(&:definition).uniq - [@wrap_definition]

        @model.entities.erase_entities((stale + orphan_edges).uniq)
        if @model.definitions.respond_to?(:remove)
          orphan_definitions.each { |d| @model.definitions.remove(d) if d.valid? && d.instances.empty? }
        end
        @stats.add(:erased_previous, stale.length)
      end

      # Reuses an existing same-named definition by clearing and refilling it
      # (v2 parity — {SpeckleObjects::Other::BlockDefinition.to_native}), so
      # re-receives don't multiply uniquified copies (`Chair#1`, `Chair#2`, …).
      # Each definition is claimed at most once per receive; a same-named second
      # claim falls through to `definitions.add`, which uniquifies.
      def claim_definition(name)
        existing = @model.definitions[name]
        if existing && !existing.group? && !existing.image? && !@claimed_definition_ids.key?(existing.entityID)
          existing.entities.clear!
          @claimed_definition_ids[existing.entityID] = true
          return existing
        end

        definition = @model.definitions.add(name)
        @claimed_definition_ids[definition.entityID] = true
        definition
      end

      # ── tags / folders (from the default scene-view path) ─────────────

      # Resolves (building lazily) the SketchUp tag for an object's scene_path
      # [folder, …, tag]: the last segment is the tag, the rest are nested folders.
      def ensure_tag_path(segments)
        return nil if segments.nil? || segments.empty?

        key = segments.join(" ")
        return @tag_by_path[key] if @tag_by_path.key?(key)

        parent_folder = ensure_folder_path(segments[0..-2])
        tag = @model.layers.add(unique_tag_name(segments))
        tag.folder = parent_folder if parent_folder && tag.respond_to?(:folder=)
        argb = @tag_color_by_path[key]
        tag.color = COLOR.from_int(argb) if argb && tag.respond_to?(:color=)
        @tag_by_path[key] = tag
      end

      def ensure_folder_path(segments)
        parent = nil
        path = []
        segments.each do |name|
          path << name
          key = path.join(" ")
          parent = (@folder_by_path[key] ||= begin
            # Reuse the same-named folder at this nesting level so re-receives
            # don't duplicate the folder tree (ENG-8850).
            siblings = parent.respond_to?(:folders) ? parent.folders : @model.layers.folders
            folder = siblings.find { |f| f.display_name == name } || @model.layers.add_folder(name)
            folder.folder = parent if parent && folder.respond_to?(:folder=) && folder.folder != parent
            folder
          end)
        end
        parent
      end

      # Full scene-path key -> tag argb (ENG-8841). Tags are created from scene_path
      # label strings, so colours are mapped by the same labels: each coloured
      # collection's path is composed with the label_chain walk that produced the
      # objects' scene_path, making the keys match by construction. Colourless
      # collections (folders, pre-colour bundles) are simply absent.
      def tag_colors_by_path(model)
        colors = {}
        model[:collections].each do |k, coll|
          next if coll[:argb].nil?

          segments = Artifacts::BundleReader.label_chain(k, model[:node_meta])
          colors[segments.join(' ')] = coll[:argb] unless segments.empty?
        end
        colors
      end

      # SketchUp tag names are globally unique, so a bare leaf is used when free; on a
      # collision (e.g. the same family name under different levels) the full path is.
      def unique_tag_name(segments)
        name = @used_tag_names.key?(segments.last) ? segments.join(' :: ') : segments.last
        name = "#{segments.join(' :: ')} (#{@uniq_counter += 1})" while @used_tag_names.key?(name)
        @used_tag_names[name] = true
        name
      end

      # ── materials ─────────────────────────────────────────────────────

      # Bakes each MATERIAL node under its authored name (pre-name bundles fall back
      # to the synthetic `speckle_<k>`), reusing an existing same-named material so
      # repeated receives don't multiply uniquified copies (`Brick Red1`, `Brick Red2`, …).
      def build_materials(materials)
        materials.each do |k, m|
          next if m[:argb].nil?

          name = m[:name].nil? || m[:name].empty? ? "speckle_#{k}" : m[:name]
          existing = @model.materials[name]
          if existing
            @material_by_k[k] = existing
            next
          end

          mat = @model.materials.add(name)
          mat.color = COLOR.from_int(m[:argb])
          mat.alpha = m[:opacity] unless m[:opacity].nil?
          @material_by_k[k] = mat
        end
      end

      # ── definitions ───────────────────────────────────────────────────

      def build_definitions(model)
        model[:definitions].each do |k, info|
          definition = claim_definition(info[:name] || "speckle_def_#{k}")
          apply_definition_meta(definition, model[:definition_meta][k] || model[:definition_meta][info[:name]])
          info[:geometry_ks].each do |geom_k|
            geometry = model[:geometries][geom_k]
            next if geometry.nil?

            material = @material_by_k[model[:material_by_geom][geom_k]]
            add_geometry(definition.entities, geometry, material, true)
          end
          @definition_by_k[k] = definition
        end
        # nested instances (DEFINES_INSTANCE) — definitions exist now, so wire placements
        model[:definitions].each do |k, info|
          info[:instance_ks].each do |inst_k|
            instance = place_instance(@definition_by_k[k].entities, model[:instances][inst_k])
            apply_instance_meta(instance, model[:instance_meta][inst_k])
          end
        end
      end

      # Restores definition-level metadata (ENG-8842): description + attribute
      # dictionaries, joined by the definition node id (name fallback for older
      # bundles). Pre-fix bundles have no definition-proxy eav rows, so meta is
      # nil and nothing is applied.
      def apply_definition_meta(definition, meta)
        return if meta.nil?

        if meta[:description] && !meta[:description].to_s.empty? && definition.respond_to?(:description=)
          definition.description = meta[:description].to_s
        end
        apply_dictionaries(definition, meta[:dictionaries])
      end

      # Restores a nested instance's name + attribute dictionaries from its
      # `@speckle.instance_k`-stamped eav row-set.
      def apply_instance_meta(instance, meta)
        return if instance.nil? || meta.nil?

        instance.name = meta[:name].to_s if meta[:name] && !meta[:name].to_s.empty? && instance.respond_to?(:name=)
        apply_dictionaries(instance, meta[:dictionaries])
      end

      # Restores a scene object's name + attributes from its eav properties.
      # Foreign models (wrapped) additionally get the root scalars (speckle_type,
      # category, family, type, application id) in a 'Speckle' base dictionary;
      # SketchUp round-trips restore only what was authored.
      def apply_object_properties(entity, obj)
        props = obj[:properties]
        return if entity.nil? || props.nil? || props.empty?

        name = props['name']
        entity.name = name.to_s if name && !name.to_s.empty? && entity.respond_to?(:name=)
        apply_dictionaries(entity, object_dictionaries(props, obj[:app_id], include_base: !@wrap_definition.nil?))
      end

      # Splits eav paths into attribute dictionaries: 'properties.Dict.key…' keeps
      # its top-level segment as the dictionary name with the remaining path as a
      # dotted key; single-segment 'properties.x' and (when include_base) root
      # scalars land in the 'Speckle' dictionary.
      def object_dictionaries(props, app_id, include_base:)
        dicts = Hash.new { |h, k| h[k] = {} }
        props.each do |path, value|
          next if value.nil?

          if path.start_with?('properties.')
            segments = path.split('.')[1..]
            next if segments.empty?

            if segments.length == 1
              dicts['Speckle'][segments.first] = value if include_base
            else
              dicts[segments.first][segments[1..].join('.')] = value
            end
          elsif include_base && !%w[name units layer].include?(path) && !path.start_with?('@speckle.')
            dicts['Speckle'][path] = value
          end
        end
        dicts['Speckle']['application_id'] = app_id if include_base && app_id
        dicts
      end

      # SketchUp refuses writes to its internal dictionaries ("Cannot modify
      # internal attribute dictionaries"), so GSU_-prefixed ones are skipped on
      # restore — they describe the source .skp, not user data. Nested hashes
      # (from unflattened meta) are flattened to dotted keys: set_attribute can
      # only store scalars/arrays.
      def apply_dictionaries(entity, dicts)
        return if dicts.nil?

        writable = {}
        dicts.each do |name, entries|
          next if name.to_s.start_with?('GSU_') || !entries.is_a?(Hash) || entries.empty?

          writable[name] = flatten_entries(entries)
        end
        DICT.attribute_dictionaries_to_native(entity, writable) if writable.any?
      end

      def flatten_entries(hash, prefix = nil)
        hash.each_with_object({}) do |(key, value), acc|
          full_key = prefix ? "#{prefix}.#{key}" : key.to_s
          value.is_a?(Hash) ? acc.merge!(flatten_entries(value, full_key)) : acc[full_key] = value
        end
      end

      # ── objects ───────────────────────────────────────────────────────

      def build_object(model, obj)
        created =
          if obj[:display_instances].any?
            obj[:display_instances].map do |ik|
              instance = place_instance(@target, model[:instances][ik])
              apply_object_properties(instance, obj)
              instance
            end
          elsif @wrap_definition
            build_object_group(model, obj)
          else
            # SketchUp-sourced: loose faces/edges, exactly as authored.
            bake_displays(@target, model, obj)
          end

        tag = ensure_tag_path(obj[:scene_path])
        created.compact.each do |e|
          e.layer = tag if tag && e.respond_to?(:layer=)
          @created_top_level << e
        end
      end

      # A foreign (e.g. Revit) scene object with direct display geometry becomes
      # its OWN group, named after the object, with its eav baked as attribute
      # dictionaries — so selecting a wall selects the wall and Entity Info /
      # attribute inspectors show its data (v2 parity).
      def build_object_group(model, obj)
        group = @target.add_group
        baked = bake_displays(group.entities, model, obj)
        if baked.empty?
          group.erase! unless group.deleted?
          return []
        end

        apply_object_properties(group, obj)
        @stats.add(:object_groups)
        [group]
      end

      def bake_displays(entities, model, obj)
        obj[:displays].flat_map do |geom_k|
          geometry = model[:geometries][geom_k]
          next [] if geometry.nil?

          material = @material_by_k[model[:material_by_geom][geom_k]]
          add_geometry(entities, geometry, material, obj[:is_soften] != false)
        end
      end

      def place_instance(entities, instance)
        return nil if instance.nil?

        definition = @definition_by_k[instance[:def_ref]]
        return nil if definition.nil?

        @stats.add(:instances)
        entities.add_instance(definition, TRANSFORM.to_native(instance[:transform], instance[:units]))
      end

      # ── levels ────────────────────────────────────────────────────────

      # Rebuilds the producer's LEVEL nodes (Revit storeys) the way v2 did
      # ({Converters::ToNative} create_levels + create_levels_from_section_planes):
      # per level a named SectionPlane LEVEL_SHIFT_VALUE above the storey (so the
      # cut shows it) and a group with a construction-line rectangle around the
      # model footprint + a text label at the true elevation, all on a
      # '<model>-Levels' tag so they hide together.
      def build_levels(model)
        levels = model[:levels]
        return if levels.nil? || levels.empty?

        units = model[:units] || 'm'
        layer = @model.layers.add("#{@wrap_definition&.name || wrap_name || 'Speckle'}-Levels")
        corners = footprint_corners
        levels.each_value do |level|
          next if level[:elevation].nil?

          elevation = SpeckleObjects::Geometry.length_to_native(level[:elevation], units)
          name = level[:name].to_s
          section_plane = @target.add_section_plane([0, 0, elevation + LEVEL_SHIFT_VALUE], [0, 0, -1])
          section_plane.name = name
          section_plane.layer = layer
          add_level_graphics(name, elevation, corners, layer)
          @stats.add(:levels)
        end
      end

      def add_level_graphics(name, elevation, corners, layer)
        group = @target.add_group
        group.name = name
        points = corners.map { |x, y| Geom::Point3d.new(x, y, elevation) }
        clines = points.each_index.map { |i| group.entities.add_cline(points[i], points[(i + 1) % 4]) }
        text = group.entities.add_text(" #{name}", points[0])
        (clines + [text, group]).each { |o| o.layer = layer }
      end

      # The received model's XY footprint (from the wrap definition's bounds,
      # which contain all baked geometry by the time levels are built); a 10m
      # square at the origin when there is nothing to measure (v2 fallback).
      def footprint_corners
        bounds = @wrap_definition ? @wrap_definition.bounds : @model.bounds
        if bounds.empty? || bounds.diagonal.zero?
          side = SpeckleObjects::Geometry.length_to_native(10, 'm')
          return [[0, 0], [side, 0], [side, side], [0, side]]
        end

        [[bounds.min.x, bounds.min.y], [bounds.max.x, bounds.min.y],
         [bounds.max.x, bounds.max.y], [bounds.min.x, bounds.max.y]]
      end

      # ── camera views ──────────────────────────────────────────────────

      # Rebuilds the bundle's named viewpoints as SketchUp scenes (pages), the v2
      # View3d way: set the camera on the active view, then `pages.add` captures
      # it. Existing same-named pages are kept (no stomping on user scenes); the
      # bundle's default view ends up selected.
      def build_camera_views(model)
        views = model[:camera_views]
        return if views.nil? || views.empty?

        default_page = nil
        views.each do |v|
          name = v['name'].to_s.empty? ? "Scene #{v['view']}" : v['name'].to_s
          next if @model.pages.any? { |page| page.name == name }

          camera = camera_from_view(v)
          next if camera.nil?

          @model.active_view.camera = camera
          page = @model.pages.add(name)
          default_page = page if v['is_default']
          @stats.add(:camera_views)
        end
        @model.pages.selected_page = default_page if default_page
      end

      def camera_from_view(v)
        units = v['units'] || 'm'
        eye = POINT.to_native(v['pos_x'], v['pos_y'], v['pos_z'], units)
        target = v['target_x'] ? POINT.to_native(v['target_x'], v['target_y'], v['target_z'], units) : eye.offset(Geom::Vector3d.new(v['forward_x'], v['forward_y'], v['forward_z']))
        up = Geom::Vector3d.new(v['up_x'].to_f, v['up_y'].to_f, v['up_z'].to_f)
        up = Geom::Vector3d.new(0, 0, 1) unless up.valid?
        perspective = v['is_ortho'] ? false : true
        camera = Sketchup::Camera.new(eye, target, up, perspective)
        camera.aspect_ratio = v['aspect'] if v['aspect'] && v['aspect'] > 0
        if perspective
          apply_camera_fov(camera, v)
        elsif v['ortho_height']
          camera.height = SpeckleObjects::Geometry.length_to_native(v['ortho_height'], units)
        end
        camera
      rescue StandardError => e
        puts "Speckle: skipping camera view '#{v['name']}' (#{e.message})"
        nil
      end

      # The bundle's fov is VERTICAL degrees; SketchUp's Camera#fov measures
      # height or width per fov_is_height?. Height-measuring cameras take it
      # directly; width-measuring ones convert through the aspect, else fall back
      # to the (width-based) focal length.
      def apply_camera_fov(camera, v)
        fov = v['fov']
        width_fov = camera.respond_to?(:fov_is_height?) && !camera.fov_is_height?
        if fov && (!width_fov || v['aspect'])
          fov = Math.atan(Math.tan(fov * Math::PI / 360.0) * v['aspect']) * 360.0 / Math::PI if width_fov
          camera.fov = fov
        elsif v['lens_mm']
          camera.focal_length = v['lens_mm']
        end
      end

      # ── geometry ──────────────────────────────────────────────────────

      # Adds a decoded SGEO geometry (mesh or line) to `entities`. Returns the created
      # entities (faces / edge) so the caller can tag them.
      def add_geometry(entities, geometry, material, is_soften)
        case geometry[:type]
        when :mesh then add_mesh(entities, geometry, material, is_soften)
        when :line then [add_line(entities, geometry)]
        when :polyline then add_polyline(entities, geometry)
        else []
        end
      end

      # A curve-family primitive (polyline / arc / circle / curve / …) -> SketchUp
      # edges through its decoded points (SketchUp has no native NURBS).
      def add_polyline(entities, geometry)
        units = geometry[:units]
        points = geometry[:points].map { |x, y, z| POINT.to_native(x, y, z, units) }
        points << points.first if geometry[:closed] && points.length > 2
        return [] if points.length < 2

        entities.add_edges(points)
      end

      def add_mesh(entities, geometry, material, is_soften)
        polygon_mesh = @stats.time(:mesh_prep) do
          units = geometry[:units]
          points = geometry[:vertices].each_slice(3).map { |x, y, z| POINT.to_native(x, y, z, units) }
          mesh = Geom::PolygonMesh.new(points.length)
          faces = geometry[:faces].dup
          until faces.empty?
            count = faces.shift
            mesh.add_polygon(faces.shift(count).map { |i| points[i] })
          end
          @stats.add(:mesh_points, points.length)
          mesh
        end
        smooth_flags = is_soften ? 4 : 1
        before = entities.size
        # fill_from_mesh skips add_faces_from_mesh's merge-with-existing checks, which
        # is only sound when there is nothing to merge with — i.e. a fresh collection
        # (each definition's first geometry, the dominant receive path).
        @stats.time(:mesh_bake) do
          if before.zero?
            entities.fill_from_mesh(polygon_mesh, true, smooth_flags, material, material)
          else
            entities.add_faces_from_mesh(polygon_mesh, smooth_flags, material, material)
          end
        end
        # Collect only the appended slice (entities appends on add) instead of
        # grepping the whole collection — the grep was O(model) per mesh, quadratic
        # over a receive that bakes thousands of top-level meshes.
        created = @stats.time(:face_collect) do
          (before...entities.size).filter_map do |i|
            entity = entities.at(i)
            entity if entity.is_a?(Sketchup::Face)
          end
        end
        @stats.add(:meshes)
        @stats.add(:faces_created, created.length)
        @converted_faces.concat(created)
        created
      end

      def add_line(entities, geometry)
        units = geometry[:units]
        entities.add_line(
          POINT.to_native(*geometry[:start], units),
          POINT.to_native(*geometry[:end], units)
        )
      end
    end
  end
end
