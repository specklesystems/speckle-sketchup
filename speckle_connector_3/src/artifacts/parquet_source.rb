# frozen_string_literal: true

require_relative 'parquet/parquet_table_reader'

module SpeckleConnector3
  module Artifacts
    # Picks the parquet read backend for receive: the `_duckdb` native ext when it
    # is built + loadable (reads ANY 4.0 bundle — ZSTD/dict/delta, so Revit and
    # other connectors work), otherwise the pure-Ruby reader (our own UNCOMPRESSED
    # files only — fine for SketchUp -> SketchUp). Both expose `read_hashes(path)`.
    module ParquetSource
      module_function

      def read_hashes(path)
        backend.read_hashes(path)
      end

      def backend
        return @backend unless @backend.nil?

        @backend = duckdb_backend || Parquet::ParquetTableReader
      end

      # Lets a caller force a backend (mainly for tests).
      def backend=(value)
        @backend = value
      end

      def duckdb_backend
        require_relative 'duckdb_parquet_source'
        if DuckdbParquetSource.available?
          puts 'Speckle: using the _duckdb native ext for parquet reads.'
          DuckdbParquetSource.new
        end
      rescue LoadError, StandardError => e
        puts "Speckle: _duckdb ext unavailable, falling back to the pure-Ruby reader (#{e.message})"
        nil
      end
    end
  end
end
