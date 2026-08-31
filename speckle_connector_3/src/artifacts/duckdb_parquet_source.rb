# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    # Reads parquet via the `_duckdb` native ext (DuckDB `read_parquet`). DuckDB
    # decodes every 4.0 codec/encoding — ZSTD, dictionary, DELTA_BINARY_PACKED,
    # multi-row-group — so this is the backend for receiving Revit / other-connector
    # bundles that the pure-Ruby reader cannot. Exposes the same `read_hashes(path)`
    # contract as {Parquet::ParquetTableReader} so {BundleReader} is backend-agnostic.
    class DuckdbParquetSource
      # @return [Boolean] whether the native ext is built + loadable
      def self.available?
        require_relative '../ext/duckdb'
        defined?(SpeckleConnector::DuckDB::Database) ? true : false
      rescue LoadError => e
        puts "Speckle: could not load the _duckdb ext (#{e.message})"
        false
      end

      def initialize
        @db = SpeckleConnector::DuckDB::Database.new
      end

      # @return [Array<Hash>] rows as { column_name => value } (blobs come back as
      #   binary Strings, so SGEO `content` decodes directly).
      def read_hashes(path)
        @db.query("SELECT * FROM read_parquet('#{path.gsub("'", "''")}')")
      end
    end
  end
end
