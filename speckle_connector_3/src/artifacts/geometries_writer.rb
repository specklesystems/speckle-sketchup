# frozen_string_literal: true

require 'digest'
require_relative 'parquet/parquet_table_writer'

module SpeckleConnector3
  module Artifacts
    # Writes `{base}.geometries.parquet` (one row per geometry: geometryIndex,
    # content SGEO blob, id = SHA256 hex, type label). Mirrors the SDK
    # `GeometriesParquetWriter`: the underlying parquet writer flushes row groups
    # on a byte budget (bounded memory), and this layer rolls to a new shard file
    # `{base}.geometries.{N}.parquet` once a shard's uncompressed content exceeds
    # the cap (keeping each file under the viewer's per-file ceiling).
    class GeometriesWriter
      SCHEMA = [
        { name: 'geometryIndex', type: :int32, optional: false },
        { name: 'content', type: :bytes, optional: true },
        { name: 'id', type: :string, optional: true },
        { name: 'type', type: :string, optional: true }
      ].freeze

      # SGEO primitive_type byte (header offset 0x05) -> type label.
      TYPE_NAMES = {
        0 => 'mesh', 1 => 'line', 2 => 'polyline', 3 => 'polycurve', 4 => 'curve',
        5 => 'arc', 6 => 'circle', 7 => 'points', 8 => 'ellipse', 9 => 'spiral', 10 => 'box'
      }.freeze

      DEFAULT_SHARD_CAP = 1536 * 1024 * 1024 # 1.5 GiB uncompressed content per shard

      # @return [Array<String>] every shard file written, in order
      attr_reader :paths

      def initialize(output_dir, base_name, shard_cap_bytes: DEFAULT_SHARD_CAP)
        @dir = output_dir
        @base = base_name
        @cap = shard_cap_bytes
        @seen = {}
        @paths = []
        @shard = 0
        @shard_bytes = 0
        @completed = false
        delete_stale_shards
        open_shard(0)
      end

      # Adds one SGEO blob under its dense geometryIndex (deduped; first write wins).
      def add_geometry(geometry_index, sgeo)
        return if @seen.key?(geometry_index)

        @seen[geometry_index] = true

        # Roll before this blob would push the current shard past the cap (but keep a
        # single oversize blob in its own shard rather than an empty file ahead of it).
        if @shard_bytes.positive? && @shard_bytes + sgeo.bytesize > @cap
          @writer.complete
          @shard += 1
          open_shard(@shard)
        end

        id = Digest::SHA256.hexdigest(sgeo)
        @writer.add_row(geometry_index, sgeo, id, TYPE_NAMES[sgeo[5].ord] || 'unknown')
        @shard_bytes += sgeo.bytesize
      end

      def complete
        return if @completed

        @completed = true
        @writer.complete
      end

      def geometries_path
        shard_path(0)
      end

      private

      def open_shard(index)
        path = shard_path(index)
        @writer = Parquet::ParquetTableWriter.new(path, SCHEMA)
        @paths << path
        @shard_bytes = 0
      end

      def shard_path(index)
        name = index.zero? ? "#{@base}.geometries.parquet" : "#{@base}.geometries.#{index}.parquet"
        File.join(@dir, name)
      end

      def delete_stale_shards
        Dir.glob(File.join(@dir, "#{@base}.geometries*.parquet")).each { |f| File.delete(f) if File.file?(f) }
      end
    end
  end
end
