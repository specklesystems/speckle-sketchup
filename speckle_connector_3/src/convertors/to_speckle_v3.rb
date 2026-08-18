# frozen_string_literal: true

require_relative '../artifacts/objects_artifact_pipeline'
require_relative '../artifacts/op_stats'
require_relative '../ui_data/report/conversion_result'
require_relative '../artifacts/sgeo_encoder'
require_relative '../artifacts/vocab'
require_relative 'camera_views'
require_relative '../speckle_objects/geometry/length'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/other/color'
require_relative '../sketchup_model/definitions/definition_manager'
require_relative '../sketchup_model/dictionary/base_dictionary_handler'
require_relative '../sketchup_model/query/layer'

module SpeckleConnector3
  module Converters
    # Speckle 4.0 single-pass extractor: produces the client-side artefact bundle
    # (geometries.parquet + envelope.*.parquet + eav.*.parquet) DIRECTLY from
    # SketchUp entities, modeled on speckle-oda's `RevitModelExtractor`. Geometry
    # is extracted straight into SGEO and streamed to disk; topology edges are
    # emitted inline; value-nodes (definitions / materials / colours / collections)
    # are emitted post-loop. This is deliberately NOT a JSON serializer — it does
    # not build a Base tree, chunk, hash, or batch.
    #
    # SketchUp's distinguishing axes vs. oda's single-container model: the tag
    # (layer) folder tree -> nested COLLECTION nodes + IN_COLLECTION (each tag
    # carries its colour on the CONTAINER node's argb — SketchUp has no object- or
    # instance-level colour, so no HAS_COLOR edges are emitted), and component
    # instancing -> DEFINITION/INSTANCE.
    class ToSpeckleV3
      ART = SpeckleConnector3::Artifacts
      SOG = SpeckleConnector3::SpeckleObjects::Geometry
      SOO = SpeckleConnector3::SpeckleObjects::Other
      DICT = SpeckleConnector3::SketchupModel::Dictionary::BaseDictionaryHandler
      LAYER = SpeckleConnector3::SketchupModel::Query::Layer

      # @return [Integer] number of top-level objects emitted (totalChildrenCount)
      attr_reader :object_count

      # @return [Artifacts::OpStats] per-phase timings/counters for this send
      attr_reader :stats

      # @return [Array<UiData::Report::ConversionResult>] one entry per top-level
      # object, for the DUI send report
      attr_reader :conversion_results

      # @param units [String] speckle model units (e.g. 'm', 'mm')
      # @param output_dir [String] directory to write the parquet bundle into
      # @param version_id [String] server pre-allocated version id (bundle base name)
      # @param model_preferences [Hash, nil] the card's send settings ("Include entity
      #   attributes" + per-entity-type toggles); nil includes everything (dev harness)
      # @param stats [Artifacts::OpStats, nil] shared stats collector (one is
      #   created when not provided, so headless/test callers stay unchanged)
      def initialize(units, output_dir, version_id, model_preferences = nil, stats = nil)
        @units = units
        @pipeline = ART::ObjectsArtifactPipeline.new(output_dir, version_id)
        @object_count = 0
        @collection_ks = {}
        @model_preferences = model_preferences
        @stats = stats || Artifacts::OpStats.new('send')
        @conversion_results = []
        # Per-extract memoizations: layers/materials don't change mid-extract, so
        # the folder-path walk, colour conversion, and render-material conversion
        # run once per layer/material instead of once per entity.
        @collection_k_by_layer = {}
        @material_k_by_material = {}
      end

      # Runs the single pass + post-loop emission and flushes the bundle to disk.
      # @param entities [Array<Sketchup::Entity>] the selected top-level entities
      # @return [Array<String>] the geometry shard paths written (for the upload bundle)
      def extract(entities)
        unpacked = @stats.time(:unpack) do
          manager = SketchupModel::Definitions::DefinitionManager.new(@units)
          result = manager.unpack_entities(entities)
          @flat = manager.flat_atomic_objects
          result
        end
        @instance_proxies = unpacked.instance_proxies

        # 1. Single pass over the selected top-level entities (emit + stream as we go).
        @stats.time(:emit_objects) { entities.each { |entity| emit_top_level(entity) } }

        # 2. Post-loop: definitions (member geometry via DEFINES, nested instances via DEFINES_INSTANCE).
        @stats.time(:emit_definitions) { unpacked.instance_definition_proxies.each { |dp| emit_definition(dp) } }

        # 3. Default scene view: the tag/layer folder tree.
        @pipeline.add_scene_view(
          ART::SceneView.new(0, 'Default', true, [ART::SceneViewKey.rel(ART::RelKind::IN_COLLECTION)])
        )

        # 4. Named camera viewpoints: the model's scenes (pages).
        emit_camera_views(entities.first&.model)

        # 5. Flush the bundle to disk (parquet writes happen here).
        @stats.time(:flush) { @pipeline.complete }
        @stats.add(:objects, @object_count)
        @pipeline.geometry_paths
      end

      private

      def emit_top_level(entity)
        case entity
        when Sketchup::ComponentInstance, Sketchup::Group
          report(entity, 'Instance') { emit_instance_object(entity) }
        when Sketchup::Face
          report(entity, 'Mesh') { emit_face_object(entity) }
        when Sketchup::Edge
          report(entity, 'Line') { emit_edge_object(entity) } unless entity.faces.any?
        else
          report_unsupported(entity)
        end
      end

      # Records one DUI report row per top-level object. A failing entity is
      # reported as ERROR (with the exception) and the send continues — one bad
      # entity shouldn't sink the whole version. `result_label` is the report's
      # display vocabulary (Instance/Mesh/Line), not the eav speckle_type string
      # (which keeps its v2-compatible value as a receive join key).
      def report(entity, result_label)
        yield
        @conversion_results << UiData::Report::ConversionResult.new(
          UiData::Report::ConversionStatus::SUCCESS,
          entity.persistent_id.to_s, entity.class.to_s.split('::').last,
          entity.persistent_id.to_s, result_label, ''
        )
      rescue StandardError => e
        @conversion_results << UiData::Report::ConversionResult.new(
          UiData::Report::ConversionStatus::ERROR,
          entity.persistent_id.to_s, entity.class.to_s.split('::').last,
          nil, nil, '', e
        )
      end

      # An entity type the 4.0 send path doesn't convert (Text, Dimension,
      # construction geometry, …) -> a WARNING row so nothing drops silently.
      def report_unsupported(entity)
        kind = entity.class.to_s.split('::').last
        @conversion_results << UiData::Report::ConversionResult.new(
          UiData::Report::ConversionStatus::WARNING,
          (entity.persistent_id.to_s if entity.respond_to?(:persistent_id)),
          kind, nil, nil, "#{kind} is not supported yet — skipped"
        )
      end

      # A component/group placement -> object with a DISPLAY_INSTANCE edge to its INSTANCE node.
      def emit_instance_object(entity)
        app_id = entity.persistent_id.to_s
        obj_k = @pipeline.intern_object(app_id)
        in_collection(obj_k, entity)
        add_properties(app_id, entity, 'Speckle.Core.Models.Instances.InstanceProxy', entity.name)

        proxy = @instance_proxies[app_id]
        def_id = entity.definition.persistent_id.to_s
        def_k = @pipeline.add_definition(def_id, entity.definition.name)
        inst_k = @pipeline.add_instance(app_id, def_k, proxy[:transform], proxy[:units])
        @pipeline.display_instance(obj_k, inst_k, 0)
        # The definition is this object's TYPE: the object_type link lets consumers
        # reach the definition's attributes (written post-loop in emit_definition)
        # through the standard star-schema join.
        @pipeline.add_object_type(app_id, def_id)
        # Instance-painted material (ENG-8849): default-material faces inside the
        # definition inherit it, so it must ride on the INSTANCE node, not the
        # shared geometry (same definition can be painted red and blue per placement).
        bind_material(inst_k, entity.material, instance: true, painted_object_k: obj_k)
        @object_count += 1
      end

      # A top-level face -> object with a world-coordinate mesh (DISPLAY).
      def emit_face_object(face)
        app_id = face.persistent_id.to_s
        obj_k = @pipeline.intern_object(app_id)
        in_collection(obj_k, face)
        # Edge soft/smooth: the authoritative signal is SGEO HardEdges (bit 11) on
        # the blob (emit_mesh). This eav row is TRANSITIONAL — old receives read
        # only @speckle.is_soften; it dies at the stamp cut-over.
        add_properties(app_id, face, 'Objects.Geometry.Mesh', nil, [['@speckle.is_soften', soften?([face])]])

        geom_k = emit_mesh(app_id, [face])
        @pipeline.display(obj_k, geom_k, 0)
        bind_material(geom_k, face.material || face.back_material)
        @object_count += 1
      end

      # A free top-level edge (not bounding a face) -> object with a Line (DISPLAY).
      def emit_edge_object(edge)
        app_id = edge.persistent_id.to_s
        obj_k = @pipeline.intern_object(app_id)
        in_collection(obj_k, edge)
        add_properties(app_id, edge, 'Objects.Geometry.Line', nil)

        geom_k = @pipeline.add_geometry(app_id, edge_to_sgeo(edge))
        @pipeline.display(obj_k, geom_k, 0)
        @object_count += 1
      end

      # Emits a definition node + its metadata + member geometry/instances.
      def emit_definition(definition_proxy)
        def_id = definition_proxy.definition.persistent_id.to_s
        def_k = @pipeline.add_definition(def_id, definition_proxy[:name])
        add_definition_type(def_id, definition_proxy.definition)
        ord = 0
        definition_proxy.object_ids.each do |member_id|
          member = @flat[member_id]
          next if member.nil?

          case member
          when SOG::GroupedMesh
            geom_k = emit_mesh(member_id, member.faces)
            @pipeline.defines(def_k, geom_k, ord)
            bind_material(geom_k, member.material)
            member_obj_k = member_tag(member_id, member.layer, geom_k: geom_k)
            @pipeline.defines_member(def_k, member_obj_k, ord) if member_obj_k
            ord += 1
          when Sketchup::ComponentInstance, Sketchup::Group
            proxy = @instance_proxies[member_id]
            next if proxy.nil?

            nested_def_k = @pipeline.add_definition(member.definition.persistent_id.to_s, member.definition.name)
            inst_k = @pipeline.add_instance(member_id, nested_def_k, proxy[:transform], proxy[:units])
            @pipeline.defines_instance(def_k, inst_k, ord)
            # A tagged OR painted nested instance gets an object row + IN_COLLECTION,
            # exactly like a top-level instance (ENG-8851); `force` guarantees the
            # `@speckle.instance_k` eav stamp receive joins the tag back through.
            # The object row also anchors the new-vocabulary edges: PLACES (24,
            # association to the placement) + DEFINES_MEMBER (25, ord = the member
            # ordinal shared with this member's DEFINES_INSTANCE row) + the rel-26
            # paint (fill semantics; geometry-level HAS_MATERIAL wins).
            tagged = member_tag(member_id, member.layer)
            painted = !member.material.nil?
            member_obj_k = add_instance_properties(member_id, inst_k, member, force: !tagged.nil? || painted)
            if member_obj_k
              @pipeline.places(member_obj_k, inst_k)
              @pipeline.defines_member(def_k, member_obj_k, ord)
            end
            bind_material(inst_k, member.material, instance: true, painted_object_k: member_obj_k)
            ord += 1
          when Sketchup::Edge
            geom_k = @pipeline.add_geometry(member_id, edge_to_sgeo(member))
            @pipeline.defines(def_k, geom_k, ord)
            member_obj_k = member_tag(member_id, member.layer, geom_k: geom_k)
            @pipeline.defines_member(def_k, member_obj_k, ord) if member_obj_k
            ord += 1
          else
            report_unsupported(member)
          end
        end
      end

      # ── geometry ──────────────────────────────────────────────────────

      # Flattens the faces into flat vertices + a Speckle face stream (in the
      # faces' own coordinate space — world for top-level, local for definition
      # members), SGEO-encodes, and interns the blob. Returns the geometry K.
      def emit_mesh(mesh_app_id, faces)
        vertices, polygons = faces_to_mesh_arrays(faces)
        # HardEdges (SGEO bit 11) rides the blob — per-geometry and authoritative.
        # Definition members gain soft/hard fidelity through it too: they never
        # carried the object-plane @speckle.is_soften eav.
        blob = ART::SgeoEncoder.encode_mesh(vertices, polygons, @units, hard_edges: !soften?(faces))
        @pipeline.add_geometry(mesh_app_id, blob)
      end

      # Single-loop faces emit one n-gon from their outer loop (v2 parity, ENG-8845 —
      # no diagonal edges on receive, smaller payloads); only holed faces fall back
      # to SketchUp's triangulation (`face.mesh`), which is what carries the holes.
      def faces_to_mesh_arrays(faces)
        vertices = []
        polygons = []
        faces.each do |face|
          base = vertices.length / 3
          if face.loops.length > 1
            mesh = face.mesh
            mesh.points.each { |pt| push_point(vertices, pt) }
            mesh.polygons.each do |poly|
              polygons.push(poly.length)
              poly.each { |i| polygons.push(base + i.abs - 1) } # PolygonMesh indices are 1-based, signed
            end
          else
            loop_vertices = face.outer_loop.vertices
            loop_vertices.each { |v| push_point(vertices, v.position) }
            polygons.push(loop_vertices.length)
            loop_vertices.each_index { |i| polygons.push(base + i) }
          end
        end
        [vertices, polygons]
      end

      def push_point(vertices, pt)
        vertices.push(
          SOG.length_to_speckle(pt.x, @units),
          SOG.length_to_speckle(pt.y, @units),
          SOG.length_to_speckle(pt.z, @units)
        )
      end

      def edge_to_sgeo(edge)
        a = edge.start.position
        b = edge.end.position
        ART::SgeoEncoder.encode_line(point_to_speckle(a), point_to_speckle(b), @units)
      end

      def point_to_speckle(point)
        [
          SOG.length_to_speckle(point.x, @units),
          SOG.length_to_speckle(point.y, @units),
          SOG.length_to_speckle(point.z, @units)
        ]
      end

      # ── camera views ──────────────────────────────────────────────────

      # Emits one {Artifacts::CameraView} per scene (page) that saves camera state
      # -> the optional `{base}.envelope.camera_views.parquet` artefact (no file
      # when the model has no scenes). Extraction (inch->model-unit conversion,
      # vertical fov, projection scalars) lives in {Converters::CameraViews}.
      def emit_camera_views(model)
        CameraViews.from_model(model, @units).each { |view| @pipeline.add_camera_view(view) }
      end

      # ── materials / colours / collections / properties ────────────────

      # `instance: true` marks placement painting (src is an INSTANCE node K, not
      # a geometry K) — rides the rel's ord as the namespace discriminator.
      # `painted_object_k` is the painted placement's OBJECT row (top-level
      # instance object, or forced member object): when given, the paint is also
      # emitted as OBJECT_HAS_MATERIAL (rel 26), the successor vocabulary — the
      # ord=1-stamped rel-5 edge stays for pre-rel-26 consumers.
      def bind_material(src_k, material, instance: false, painted_object_k: nil)
        return if material.nil?

        mat_k = @material_k_by_material[material.persistent_id] ||= begin
          rm = SOO::RenderMaterial.from_material(material)
          # Authored PBR values, nil when disabled/unsupported (ENG-9121) — not
          # v2's fixed metalness 0 / roughness 1.
          metalness, roughness = SOO::RenderMaterial.pbr_channels(material)
          @pipeline.add_material(material.persistent_id.to_s, rm[:name], rm[:diffuse], rm[:opacity], metalness, roughness)
        end
        @pipeline.has_material(src_k, mat_k, instance: instance)
        @pipeline.object_has_material(painted_object_k, mat_k) if instance && painted_object_k
      end

      def in_collection(obj_k, entity)
        layer_k = layer_collection_k(entity.layer)
        @pipeline.in_collection(obj_k, layer_k, 0) if layer_k
      end

      def layer_collection_k(layer)
        return nil if layer.nil?

        @collection_k_by_layer[layer.persistent_id] ||= collection_k_for_layer(layer)
      end

      # Tag membership for definition content (ENG-8851): a tagged member gets an
      # object row under its own app id and the standard
      # IN_COLLECTION(object -> collection) edge, exactly like a top-level
      # object. For meshes/edges the object joins back to its geometry via an
      # `@speckle.geometry_k` eav stamp (the `@speckle.instance_k` pattern —
      # object and geometry indexes are separate id spaces; kept this release for
      # old consumers) and, in the successor vocabulary, via DEFINES_MEMBER's
      # (definition, ord) join emitted by the caller. Default-tag members emit
      # nothing: receive's default is already Untagged. Returns the member's
      # object K when tagged, nil otherwise.
      def member_tag(app_id, layer, geom_k: nil)
        return nil unless member_tagged?(layer)

        layer_k = layer_collection_k(layer)
        return nil if layer_k.nil?

        obj_k = @pipeline.intern_object(app_id)
        @pipeline.in_collection(obj_k, layer_k, 0)
        @pipeline.add_properties(app_id, {}, [['@speckle.geometry_k', geom_k]]) unless geom_k.nil?
        obj_k
      end

      def member_tagged?(layer)
        !layer.nil? && !%w[Layer0 Untagged].include?(layer.display_name)
      end

      # Resolves (building lazily) the COLLECTION node for an entity's tag, nesting
      # it under its folder ancestry. Returns the leaf (tag) collection K.
      def collection_k_for_layer(layer)
        return nil if layer.nil?

        parent_k = nil
        LAYER.path(layer).each do |folder|
          parent_k = ensure_collection(folder.persistent_id.to_s, folder.display_name, parent_k, 'Folder')
        end
        ensure_collection(layer.persistent_id.to_s, layer.display_name, parent_k, 'Layer',
                          SOO::Color.to_int(layer.color))
      end

      # subtype 'Folder' for tag folders, 'Layer' for tags — so receive rebuilds each
      # as the right SketchUp object (LayerFolder vs Layer). Tags carry their colour
      # on the container node's argb (the cross-connector layer-colour pattern);
      # folders have no colour in SketchUp.
      def ensure_collection(key, name, parent_k, subtype, argb = nil)
        @collection_ks[key] ||= @pipeline.add_collection(key, name, parent_k, subtype, argb)
      end

      def add_properties(app_id, entity, speckle_type, name, extra = [])
        root = [['speckle_type', speckle_type], ['units', @units], ['layer', LAYER.entity_path(entity)]]
        root << ['name', name] if name && name != ''
        root.concat(extra)
        @pipeline.add_properties(app_id, entity_dictionaries(entity), root)
      end

      # Definition-level metadata (ENG-8842): description + definition attribute
      # dictionaries ride the TYPE tables (types/type_eav), keyed by the
      # definition's persistent id as the type_key. Definitions are not
      # interactable scene objects, so they never enter the objects table —
      # placements reach these rows through their object_type link. Written once
      # per definition regardless of placement count. Dictionaries are
      # re-extracted through the send settings here — NOT taken from the proxy's
      # copy, which DefinitionManager extracts unfiltered (ENG-8843).
      # No @speckle.definition_k stamp (removed with the vocab rels): receive
      # joins definition meta by NAME, unique in SketchUp — the reader keeps the
      # stamp fallback for old bundles.
      def add_definition_type(def_id, definition)
        root = [['speckle_type', 'Speckle.Core.Models.Instances.InstanceDefinitionProxy'], ['name', definition.name]]
        description = definition.description
        root << ['description', description] if description && description != ''
        @pipeline.add_type_properties(def_id, entity_dictionaries(definition), root)
      end

      # Nested-instance metadata: attribute dictionaries + name, keyed by the
      # member's own persistent id, with the INSTANCE node's dense id as the join
      # key for receive. Emitted only when there is something to carry, so plain
      # unnamed placements add no eav rows.
      # Returns the member's object K when a row-set was written, nil otherwise.
      def add_instance_properties(app_id, inst_k, entity, force: false)
        dicts = entity_dictionaries(entity)
        name = entity.name.to_s
        return nil if dicts.empty? && name.empty? && !force

        root = [['speckle_type', 'Speckle.Core.Models.Instances.InstanceProxy'], ['@speckle.instance_k', inst_k]]
        root << ['name', name] unless name.empty?
        @pipeline.add_properties(app_id, dicts, root)
        # A nested placement that carries an eav row-set links to its definition
        # type like a top-level object does; plain placements emit no object row,
        # so they get no link either (object_type never outgrows objects — their
        # definition membership is already in the envelope via DEFINES_INSTANCE).
        @pipeline.add_object_type(app_id, entity.definition.persistent_id.to_s)
        @pipeline.intern_object(app_id)
      end

      # Honours the "Include entity attributes" send settings (ENG-8843) with v2's
      # exact filtering; without preferences (dev harness) everything is included.
      def entity_dictionaries(entity)
        return DICT.attribute_dictionaries_to_speckle(entity) if @model_preferences.nil?

        DICT.attribute_dictionaries_to_speckle_by_settings(entity, @model_preferences)
      end

      # True if any of the faces has a soft edge (the existing Mesh.from_face rule).
      def soften?(faces)
        faces.any? { |face| face.edges.any?(&:soft?) }
      end
    end
  end
end
