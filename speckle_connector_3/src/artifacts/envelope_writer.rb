# frozen_string_literal: true

require_relative 'parquet/parquet_table_writer'
require_relative 'vocab'
require_relative '../constants/app_constants'

module SpeckleConnector3
  module Artifacts
    # Writes the envelope topology artefact: `{base}.envelope.relations.parquet`
    # (typed edges) + `.nodes.parquet` (value-entities) + the self-describing
    # `.meta`/`.rel_types`/`.node_kinds` catalog (written once) + optional
    # `.scene_views.parquet` (producer-authored projections) + optional
    # `.camera_views.parquet` (named camera viewpoints). Mirrors the
    # `speckle-bundle-spec` generated schemas (and the SDK `EnvelopeWriter`);
    # SCHEMA_VERSION must stay in lockstep with `BundleSpec.SchemaVersion`.
    class EnvelopeWriter
      SCHEMA_VERSION = 5

      RELATIONS_SCHEMA = [
        { name: 'rel', type: :int32, optional: false },
        { name: 'src', type: :int32, optional: false },
        { name: 'dst', type: :int32, optional: false },
        { name: 'ord', type: :int32, optional: true }
      ].freeze

      NODES_SCHEMA = [
        { name: 'id', type: :int32, optional: false },
        { name: 'kind', type: :int32, optional: false },
        { name: 'name', type: :string, optional: true },
        { name: 'def_ref', type: :int32, optional: true },
        { name: 'transform', type: :string, optional: true },
        { name: 'units', type: :string, optional: true },
        { name: 'subtype', type: :string, optional: true },
        { name: 'argb', type: :int32, optional: true },
        { name: 'opacity', type: :double, optional: true },
        { name: 'metalness', type: :double, optional: true },
        { name: 'roughness', type: :double, optional: true },
        { name: 'elevation', type: :double, optional: true }
      ].freeze

      # rel code -> [name, src_ns, dst_ns] — the cross-connector vocabulary catalog
      # (live + reserved rows only; retired ids stay vacant).
      REL_TYPES = [
        [1, 'DISPLAY', 'object', 'geometry'], [2, 'SOLID', 'object', 'geometry'],
        [3, 'SUBELEMENT', 'object', 'object'], [4, 'DEFINES', 'node', 'geometry'],
        [5, 'HAS_MATERIAL', 'geometry', 'node'], [6, 'HAS_COLOR', 'geometry|object', 'node'],
        [7, 'ON_LEVEL', 'object', 'node'], [8, 'DISPLAY_INSTANCE', 'object', 'node'],
        [9, 'DEFINES_INSTANCE', 'node', 'node'], [10, 'IN_COLLECTION', 'object', 'node'],
        [11, 'IN_MODEL', 'object', 'node'], [12, 'IN_ROOM', 'object', 'object'],
        [14, 'IN_SYSTEM', 'object', 'node'], [21, 'CONNECTS_TO', 'object', 'object'],
        [23, 'BOUNDS', 'object', 'object']
      ].freeze

      NODE_KINDS = [
        [1, 'DEFINITION'], [2, 'INSTANCE'], [3, 'MATERIAL'], [4, 'COLOR'],
        [5, 'LEVEL'], [7, 'CONTAINER']
      ].freeze

      def initialize(output_dir, base_name)
        @dir = output_dir
        @base = base_name
        @relations = Parquet::ParquetTableWriter.new(path('relations.parquet'), RELATIONS_SCHEMA)
        @nodes = Parquet::ParquetTableWriter.new(path('nodes.parquet'), NODES_SCHEMA)
        @scene_views = []
        @camera_views = []
        @completed = false
        write_catalog
      end

      def add_relation(rel, src, dst, ord)
        @relations.add_row(rel, src, dst, ord)
      end

      # rubocop:disable Metrics/ParameterLists
      def add_node(id, kind, name, def_ref, transform, units, subtype, argb, opacity, metalness, roughness, elevation)
        @nodes.add_row(id, kind, name, def_ref, transform, units, subtype, argb, opacity, metalness, roughness, elevation)
      end
      # rubocop:enable Metrics/ParameterLists

      def add_scene_view(view)
        @scene_views << view
      end

      def add_camera_view(view)
        @camera_views << view
      end

      def complete
        return if @completed

        @completed = true
        @relations.complete
        @nodes.complete
        write_scene_views
        write_camera_views
      end

      private

      def write_catalog
        meta = Parquet::ParquetTableWriter.new(
          path('meta.parquet'),
          [{ name: 'schema_version', type: :int32, optional: false },
           { name: 'produced_by', type: :string, optional: true }]
        )
        # meta.produced_by carries the host-app slug (not a writer class name) — consumers
        # (e.g. `to_native_v3`) branch on it to detect same-app round-trips.
        meta.add_row(SCHEMA_VERSION, HOST_APP_SLUG)
        meta.complete

        rt = Parquet::ParquetTableWriter.new(
          path('rel_types.parquet'),
          [{ name: 'rel', type: :int32, optional: false },
           { name: 'name', type: :string, optional: true },
           { name: 'src_ns', type: :string, optional: true },
           { name: 'dst_ns', type: :string, optional: true }]
        )
        REL_TYPES.each { |rel, name, src_ns, dst_ns| rt.add_row(rel, name, src_ns, dst_ns) }
        rt.complete

        nk = Parquet::ParquetTableWriter.new(
          path('node_kinds.parquet'),
          [{ name: 'kind', type: :int32, optional: false },
           { name: 'name', type: :string, optional: true }]
        )
        NODE_KINDS.each { |kind, name| nk.add_row(kind, name) }
        nk.complete
      end

      def write_scene_views
        return if @scene_views.empty?

        sv = Parquet::ParquetTableWriter.new(
          path('scene_views.parquet'),
          [{ name: 'view', type: :int32, optional: false },
           { name: 'name', type: :string, optional: true },
           { name: 'is_default', type: :boolean, optional: false },
           { name: 'ord', type: :int32, optional: false },
           { name: 'source', type: :string, optional: true },
           { name: 'ref', type: :string, optional: true }]
        )
        @scene_views.each do |view|
          view.keys.each_with_index do |key, ord|
            sv.add_row(view.view, view.name, view.is_default, ord, key.source, key.ref)
          end
        end
        sv.complete
      end

      # Optional artefact: written only when at least one camera view was added —
      # an absent file means "the model ships no viewpoints" (bundle-spec table 14).
      # One row per view; column order/nullability is the frozen `camera_views`
      # schema from `speckle-bundle-spec`.
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def write_camera_views
        return if @camera_views.empty?

        cv = Parquet::ParquetTableWriter.new(
          path('camera_views.parquet'),
          [{ name: 'view', type: :int32, optional: false },
           { name: 'name', type: :string, optional: true },
           { name: 'is_default', type: :boolean, optional: true },
           { name: 'ord', type: :int32, optional: true },
           { name: 'pos_x', type: :double, optional: false },
           { name: 'pos_y', type: :double, optional: false },
           { name: 'pos_z', type: :double, optional: false },
           { name: 'forward_x', type: :double, optional: false },
           { name: 'forward_y', type: :double, optional: false },
           { name: 'forward_z', type: :double, optional: false },
           { name: 'up_x', type: :double, optional: false },
           { name: 'up_y', type: :double, optional: false },
           { name: 'up_z', type: :double, optional: false },
           { name: 'target_x', type: :double, optional: true },
           { name: 'target_y', type: :double, optional: true },
           { name: 'target_z', type: :double, optional: true },
           { name: 'units', type: :string, optional: true },
           { name: 'is_ortho', type: :boolean, optional: true },
           { name: 'fov', type: :double, optional: true },
           { name: 'lens_mm', type: :double, optional: true },
           { name: 'ortho_height', type: :double, optional: true },
           { name: 'aspect', type: :double, optional: true },
           { name: 'near', type: :double, optional: true },
           { name: 'far', type: :double, optional: true }]
        )
        @camera_views.each do |v|
          target = v.target || [nil, nil, nil]
          cv.add_row(
            v.view, v.name, v.is_default, v.ord,
            v.pos[0], v.pos[1], v.pos[2],
            v.forward[0], v.forward[1], v.forward[2],
            v.up[0], v.up[1], v.up[2],
            target[0], target[1], target[2],
            v.units, v.is_ortho, v.fov, v.lens_mm, v.ortho_height, v.aspect, v.near, v.far
          )
        end
        cv.complete
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def path(suffix)
        File.join(@dir, "#{@base}.envelope.#{suffix}")
      end
    end
  end
end
