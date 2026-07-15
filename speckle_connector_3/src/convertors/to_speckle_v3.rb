# frozen_string_literal: true

require_relative '../artifacts/objects_artifact_pipeline'
require_relative '../artifacts/op_stats'
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
    # (layer) folder tree -> nested COLLECTION nodes + IN_COLLECTION, layer colours
    # -> COLOR nodes + HAS_COLOR, and component instancing -> DEFINITION/INSTANCE.
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
        # Per-extract memoizations: layers/materials don't change mid-extract, so
        # the folder-path walk, colour conversion, and render-material conversion
        # run once per layer/material instead of once per entity.
        @collection_k_by_layer = {}
        @color_int_by_layer = {}
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
          emit_instance_object(entity)
        when Sketchup::Face
          emit_face_object(entity)
        when Sketchup::Edge
          emit_edge_object(entity) unless entity.faces.any?
        end
      end

      # A component/group placement -> object with a DISPLAY_INSTANCE edge to its INSTANCE node.
      def emit_instance_object(entity)
        app_id = entity.persistent_id.to_s
        obj_k = @pipeline.intern_object(app_id)
        in_collection(obj_k, entity)
        add_properties(app_id, entity, 'Speckle.Core.Models.Instances.InstanceProxy', entity.name)

        proxy = @instance_proxies[app_id]
        def_k = @pipeline.add_definition(entity.definition.persistent_id.to_s, entity.definition.name)
        inst_k = @pipeline.add_instance(app_id, def_k, proxy[:transform], proxy[:units])
        @pipeline.display_instance(obj_k, inst_k, 0)
        add_color(obj_k, entity)
        @object_count += 1
      end

      # A top-level face -> object with a world-coordinate mesh (DISPLAY).
      def emit_face_object(face)
        app_id = face.persistent_id.to_s
        obj_k = @pipeline.intern_object(app_id)
        in_collection(obj_k, face)
        # Carry edge soft/smooth so receive can restore it (eav boolean; the geometry
        # formats are cross-connector and have no place for host-specific flags).
        add_properties(app_id, face, 'Objects.Geometry.Mesh', nil, [['@speckle.is_soften', soften?([face])]])

        geom_k = emit_mesh(app_id, [face])
        @pipeline.display(obj_k, geom_k, 0)
        bind_material(geom_k, face.material || face.back_material)
        add_color(obj_k, face)
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
        add_color(obj_k, edge)
        @object_count += 1
      end

      # Emits a definition node + its metadata + member geometry/instances.
      def emit_definition(definition_proxy)
        def_id = definition_proxy.definition.persistent_id.to_s
        def_k = @pipeline.add_definition(def_id, definition_proxy[:name])
        add_definition_properties(def_id, def_k, definition_proxy.definition)
        ord = 0
        definition_proxy.object_ids.each do |member_id|
          member = @flat[member_id]
          next if member.nil?

          case member
          when SOG::GroupedMesh
            geom_k = emit_mesh(member_id, member.faces)
            @pipeline.defines(def_k, geom_k, ord)
            bind_material(geom_k, member.material)
            ord += 1
          when Sketchup::ComponentInstance, Sketchup::Group
            proxy = @instance_proxies[member_id]
            next if proxy.nil?

            nested_def_k = @pipeline.add_definition(member.definition.persistent_id.to_s, member.definition.name)
            inst_k = @pipeline.add_instance(member_id, nested_def_k, proxy[:transform], proxy[:units])
            @pipeline.defines_instance(def_k, inst_k, ord)
            add_instance_properties(member_id, inst_k, member)
            ord += 1
          when Sketchup::Edge
            geom_k = @pipeline.add_geometry(member_id, edge_to_sgeo(member))
            @pipeline.defines(def_k, geom_k, ord)
            ord += 1
          end
        end
      end

      # ── geometry ──────────────────────────────────────────────────────

      # Flattens the faces into flat vertices + a Speckle face stream (in the
      # faces' own coordinate space — world for top-level, local for definition
      # members), SGEO-encodes, and interns the blob. Returns the geometry K.
      def emit_mesh(mesh_app_id, faces)
        vertices, polygons = faces_to_mesh_arrays(faces)
        @pipeline.add_geometry(mesh_app_id, ART::SgeoEncoder.encode_mesh(vertices, polygons, @units))
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

      def bind_material(geom_k, material)
        return if material.nil?

        mat_k = @material_k_by_material[material.persistent_id] ||= begin
          rm = SOO::RenderMaterial.from_material(material)
          @pipeline.add_material(material.persistent_id.to_s, rm[:name], rm[:diffuse], rm[:opacity], rm[:metalness], rm[:roughness])
        end
        @pipeline.has_material(geom_k, mat_k)
      end

      # Binds the object to its tag (layer) colour — SketchUp's "colour by tag".
      def add_color(obj_k, entity)
        layer = entity.layer
        return if layer.nil?

        argb = @color_int_by_layer[layer.persistent_id] ||= SOO::Color.to_int(layer.color)
        @pipeline.has_color(obj_k, @pipeline.add_color(argb))
      end

      def in_collection(obj_k, entity)
        layer = entity.layer
        return if layer.nil?

        layer_k = @collection_k_by_layer[layer.persistent_id] ||= collection_k_for_layer(layer)
        @pipeline.in_collection(obj_k, layer_k, 0) if layer_k
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
      # dictionaries ride the eav table keyed by the definition's persistent id.
      # Dictionaries are re-extracted through the send settings here — NOT taken from
      # the proxy's copy, which DefinitionManager extracts unfiltered (ENG-8843).
      # `@speckle.definition_k` carries the DEFINITION node's dense id so receive
      # joins back exactly (envelope nodes carry no application id).
      def add_definition_properties(def_id, def_k, definition)
        root = [['speckle_type', 'Speckle.Core.Models.Instances.InstanceDefinitionProxy'], ['name', definition.name],
                ['@speckle.definition_k', def_k]]
        description = definition.description
        root << ['description', description] if description && description != ''
        @pipeline.add_properties(def_id, entity_dictionaries(definition), root)
      end

      # Nested-instance metadata: attribute dictionaries + name, keyed by the
      # member's own persistent id, with the INSTANCE node's dense id as the join
      # key for receive. Emitted only when there is something to carry, so plain
      # unnamed placements add no eav rows.
      def add_instance_properties(app_id, inst_k, entity)
        dicts = entity_dictionaries(entity)
        name = entity.name.to_s
        return if dicts.empty? && name.empty?

        root = [['speckle_type', 'Speckle.Core.Models.Instances.InstanceProxy'], ['@speckle.instance_k', inst_k]]
        root << ['name', name] unless name.empty?
        @pipeline.add_properties(app_id, dicts, root)
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
