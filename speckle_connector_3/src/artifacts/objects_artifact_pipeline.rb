# frozen_string_literal: true

require_relative 'geometries_writer'
require_relative 'eav_writer'
require_relative 'envelope_writer'
require_relative 'eav_extraction'
require_relative 'id_interner'
require_relative 'vocab'

module SpeckleConnector3
  module Artifacts
    # Producer façade for the 4.0 artefact bundle — a pure-Ruby mirror of the SDK
    # `Speckle.Objects.Utils.ObjectsArtifactPipeline`. Owns the three artefact
    # writers + the per-namespace identity interners (object via the eav writer,
    # geometry, node with kind-prefixed keys) and exposes the typed emit API the
    # extractor drives. Geometry blobs stream to disk during emit; eav/envelope
    # tables flush on `complete`.
    class ObjectsArtifactPipeline
      def initialize(output_dir, base_name, excluded_top_level: EavExtraction::DEFAULT_EXCLUDED_TOP_LEVEL)
        @geometries = GeometriesWriter.new(output_dir, base_name)
        @envelope = EnvelopeWriter.new(output_dir, base_name)
        @eav = EavWriter.new(output_dir, base_name)
        @excluded = excluded_top_level
        @geometry_interner = IdInterner.new
        @node_interner = IdInterner.new
      end

      # @return [Array<String>] the geometry shard files written (for the upload bundle)
      def geometry_paths
        @geometries.paths
      end

      # ── object namespace ──────────────────────────────────────────────

      # Resolves an object's dense K (interns applicationId via the eav dictionary).
      def intern_object(application_id)
        @eav.get_or_add_object(application_id)
      end

      # Flattens an object's property tree into eav, keyed by applicationId.
      # @param properties [Hash] nested property dictionary (geometry excluded)
      # @param root_scalars [Array<Array(String,Object)>] bare top-level labels
      def add_properties(application_id, properties, root_scalars = [])
        rows = EavExtraction.flatten_properties(properties, root_scalars, excluded: @excluded)
        @eav.add_rows(application_id, rows)
      end

      # Flattens a TYPE's property tree into type_eav, keyed by type_key.
      # SketchUp's "type" is the component definition: attributes shared by every
      # placement live here (written once per type_key, later calls no-op), and
      # the definition never enters the objects table — it is not an interactable
      # scene object. Returns the dense type_index.
      def add_type_properties(type_key, properties, root_scalars = [])
        rows = EavExtraction.flatten_properties(properties, root_scalars, excluded: @excluded)
        @eav.add_type_rows(type_key, rows)
      end

      # Links an object to its type in object_type (objects -> object_type ->
      # type_eav, the standard star-schema join).
      def add_object_type(application_id, type_key)
        @eav.add_object_type(application_id, type_key)
      end

      # ── geometry namespace ────────────────────────────────────────────

      # Interns a mesh applicationId to a dense geometry K, writing the SGEO blob on
      # first sight, and returns the K (for DISPLAY / DEFINES / HAS_MATERIAL edges).
      def add_geometry(mesh_application_id, sgeo)
        is_new, k = @geometry_interner.get_or_add(mesh_application_id)
        @geometries.add_geometry(k, sgeo) if is_new
        k
      end

      # Resolves the geometry K for an already-added mesh (no write) — for post-loop
      # DEFINES / HAS_MATERIAL edges referencing meshes by host applicationId.
      def intern_geometry_id(mesh_application_id)
        @geometry_interner.id_for(mesh_application_id)
      end

      # ── node namespace (value-entities) ───────────────────────────────

      def add_definition(definition_key, name)
        node('def:' + definition_key) { |k| @envelope.add_node(k, NodeKind::DEFINITION, name, nil, nil, nil, nil, nil, nil, nil, nil, nil) }
      end

      def add_instance(placement_key, def_ref, transform, units)
        node('inst:' + placement_key) do |k|
          @envelope.add_node(k, NodeKind::INSTANCE, nil, def_ref, format_transform(transform), units, nil, nil, nil, nil, nil, nil)
        end
      end

      def add_material(material_key, name, argb, opacity, metalness, roughness)
        node('mat:' + material_key) do |k|
          @envelope.add_node(k, NodeKind::MATERIAL, name, nil, nil, nil, nil, argb, opacity, metalness, roughness, nil)
        end
      end

      def add_color(argb)
        node('col:' + argb.to_s) { |k| @envelope.add_node(k, NodeKind::COLOR, nil, nil, nil, nil, nil, argb, nil, nil, nil, nil) }
      end

      def add_level(level_key, name, elevation)
        node('lvl:' + level_key) { |k| @envelope.add_node(k, NodeKind::LEVEL, name, nil, nil, nil, nil, nil, nil, nil, nil, elevation) }
      end

      # Since bundle-spec v5 a collection IS a CONTAINER node — `subtype` (its own
      # column, e.g. 'Layer'/'Folder') is the only discriminator. Kept as a separate
      # method from {#add_container} for the 'coll:'-prefixed key namespace.
      # `argb` is the collection's own colour (a tag's colour), nil when it has none.
      def add_collection(collection_key, name, parent_collection_k, subtype, argb = nil)
        node('coll:' + collection_key) do |k|
          @envelope.add_node(k, NodeKind::CONTAINER, name, parent_collection_k, nil, nil, subtype, argb, nil, nil, nil, nil)
        end
      end

      def add_container(container_key, name, parent_container_k, subtype)
        node('cont:' + container_key) do |k|
          @envelope.add_node(k, NodeKind::CONTAINER, name, parent_container_k, nil, nil, subtype, nil, nil, nil, nil, nil)
        end
      end

      # ── relations ─────────────────────────────────────────────────────

      def display(object_k, geometry_k, ord)
        @envelope.add_relation(RelKind::DISPLAY, object_k, geometry_k, ord)
      end

      def display_instance(object_k, instance_k, ord)
        @envelope.add_relation(RelKind::DISPLAY_INSTANCE, object_k, instance_k, ord)
      end

      def solid(object_k, geometry_k, ord)
        @envelope.add_relation(RelKind::SOLID, object_k, geometry_k, ord)
      end

      def subelement(parent_object_k, child_object_k, ord)
        @envelope.add_relation(RelKind::SUBELEMENT, parent_object_k, child_object_k, ord)
      end

      def defines(definition_k, geometry_k, ord)
        @envelope.add_relation(RelKind::DEFINES, definition_k, geometry_k, ord)
      end

      def defines_instance(definition_k, instance_k, ord)
        @envelope.add_relation(RelKind::DEFINES_INSTANCE, definition_k, instance_k, ord)
      end

      # `src_k` is a geometry K, or an INSTANCE node K for placement painting
      # (ENG-8849). The two K-spaces overlap numerically and rel 5's src namespace
      # is their union — undecidable for a reader on collision — so `ord` (unused
      # by the spec for this rel) carries the producer's discriminator: 1 =
      # INSTANCE-sourced, 0 = geometry-sourced.
      def has_material(src_k, material_k, instance: false)
        @envelope.add_relation(RelKind::HAS_MATERIAL, src_k, material_k, instance ? 1 : 0)
      end

      def has_color(src_k, color_k)
        @envelope.add_relation(RelKind::HAS_COLOR, src_k, color_k, 0)
      end

      def on_level(object_k, level_k)
        @envelope.add_relation(RelKind::ON_LEVEL, object_k, level_k, 0)
      end

      def in_collection(object_k, collection_k, ord)
        @envelope.add_relation(RelKind::IN_COLLECTION, object_k, collection_k, ord)
      end

      def in_model(object_k, model_k, ord)
        @envelope.add_relation(RelKind::IN_MODEL, object_k, model_k, ord)
      end

      # ── scene views / camera views / lifecycle ────────────────────────

      def add_scene_view(view)
        @envelope.add_scene_view(view)
      end

      # Buffers a named camera viewpoint ({CameraView}) for the optional
      # `{base}.envelope.camera_views.parquet` artefact (no file when none added).
      def add_camera_view(view)
        @envelope.add_camera_view(view)
      end

      # Flushes all three artefacts to disk.
      def complete
        @geometries.complete
        @envelope.complete
        @eav.complete
      end

      private

      # Interns a kind-prefixed node key; yields the new K to write the node row on
      # first sight; returns the K either way.
      def node(key)
        is_new, k = @node_interner.get_or_add(key)
        yield(k) if is_new
        k
      end

      def format_transform(transform)
        transform.map { |d| d == d.to_i ? d.to_i.to_s : d.to_s }.join(',')
      end
    end
  end
end
