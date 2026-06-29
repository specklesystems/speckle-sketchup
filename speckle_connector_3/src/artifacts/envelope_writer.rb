# frozen_string_literal: true

require_relative 'parquet/parquet_table_writer'
require_relative 'vocab'

module SpeckleConnector3
  module Artifacts
    # Writes the envelope topology artefact: `{base}.envelope.relations.parquet`
    # (typed edges) + `.nodes.parquet` (value-entities) + the self-describing
    # `.meta`/`.rel_types`/`.node_kinds` catalog (written once) + optional
    # `.scene_views.parquet` (producer-authored projections). Mirrors the SDK
    # `EnvelopeWriter`; SCHEMA_VERSION must stay in lockstep with it.
    class EnvelopeWriter
      SCHEMA_VERSION = 3

      RELATIONS_SCHEMA = [
        { name: 'rel', type: :int32, optional: false },
        { name: 'src', type: :int32, optional: false },
        { name: 'dst', type: :int32, optional: false },
        { name: 'ord', type: :int32, optional: false }
      ].freeze

      NODES_SCHEMA = [
        { name: 'id', type: :int32, optional: false },
        { name: 'kind', type: :int32, optional: false },
        { name: 'name', type: :string, optional: true },
        { name: 'def_ref', type: :int32, optional: true },
        { name: 'transform', type: :string, optional: true },
        { name: 'units', type: :string, optional: true },
        { name: 'argb', type: :int32, optional: true },
        { name: 'opacity', type: :double, optional: true },
        { name: 'metalness', type: :double, optional: true },
        { name: 'roughness', type: :double, optional: true },
        { name: 'elevation', type: :double, optional: true }
      ].freeze

      # rel code -> [name, src_ns, dst_ns] — the cross-connector vocabulary catalog.
      REL_TYPES = [
        [1, 'DISPLAY', 'object', 'geometry'], [2, 'SOLID', 'object', 'geometry'],
        [3, 'SUBELEMENT', 'object', 'object'], [4, 'DEFINES', 'node', 'geometry'],
        [5, 'HAS_MATERIAL', 'geometry', 'node'], [6, 'HAS_COLOR', 'geometry|object', 'node'],
        [7, 'ON_LEVEL', 'object', 'node'], [8, 'DISPLAY_INSTANCE', 'object', 'node'],
        [9, 'DEFINES_INSTANCE', 'node', 'node'], [10, 'IN_COLLECTION', 'object', 'node'],
        [11, 'IN_MODEL', 'object', 'node'], [12, 'IN_ROOM', 'object', 'node'],
        [13, 'IN_SPACE', 'object', 'node'], [14, 'IN_SYSTEM', 'object', 'node'],
        [15, 'IN_NETWORK', 'object', 'node'], [16, 'IN_LINE', 'object', 'node'],
        [17, 'IN_GROUP', 'object', 'node'], [18, 'IN_ASSEMBLY', 'object', 'node'],
        [19, 'IN_SUBASSEMBLY', 'object', 'node'], [20, 'XREF', 'object', 'node'],
        [21, 'CONNECTS_TO', 'object', 'object'], [22, 'HOSTED_ON', 'object', 'object']
      ].freeze

      NODE_KINDS = [
        [1, 'DEFINITION'], [2, 'INSTANCE'], [3, 'MATERIAL'], [4, 'COLOR'],
        [5, 'LEVEL'], [6, 'COLLECTION'], [7, 'CONTAINER']
      ].freeze

      def initialize(output_dir, base_name)
        @dir = output_dir
        @base = base_name
        @relations = Parquet::ParquetTableWriter.new(path('relations.parquet'), RELATIONS_SCHEMA)
        @nodes = Parquet::ParquetTableWriter.new(path('nodes.parquet'), NODES_SCHEMA)
        @scene_views = []
        @completed = false
        write_catalog
      end

      def add_relation(rel, src, dst, ord)
        @relations.add_row(rel, src, dst, ord)
      end

      # rubocop:disable Metrics/ParameterLists
      def add_node(id, kind, name, def_ref, transform, units, argb, opacity, metalness, roughness, elevation)
        @nodes.add_row(id, kind, name, def_ref, transform, units, argb, opacity, metalness, roughness, elevation)
      end
      # rubocop:enable Metrics/ParameterLists

      def add_scene_view(view)
        @scene_views << view
      end

      def complete
        return if @completed

        @completed = true
        @relations.complete
        @nodes.complete
        write_scene_views
      end

      private

      def write_catalog
        meta = Parquet::ParquetTableWriter.new(
          path('meta.parquet'),
          [{ name: 'schema_version', type: :int32, optional: false },
           { name: 'produced_by', type: :string, optional: true }]
        )
        meta.add_row(SCHEMA_VERSION, 'speckle-sketchup EnvelopeWriter')
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

      def path(suffix)
        File.join(@dir, "#{@base}.envelope.#{suffix}")
      end
    end
  end
end
