# frozen_string_literal: true

require_relative 'thrift_compact'
require_relative 'column_writer'

module SpeckleConnector3
  module Artifacts
    module Parquet
      # Writes a single flat Parquet file (UNCOMPRESSED) from row-oriented input.
      # One DATA_PAGE (v1) per column per row group; row groups are flushed on a
      # byte/row budget so memory stays bounded while streaming large geometry.
      #
      # Schema is an array of column definitions:
      #   { name: 'object_index', type: :int32,   optional: false }
      #   { name: 'application_id', type: :string, optional: true  }
      #   { name: 'content',        type: :bytes,  optional: true  }
      #   { name: 'value_double',   type: :double, optional: true  }
      #   { name: 'value_boolean',  type: :boolean,optional: true  }
      #
      # File layout: "PAR1" <row groups...> <FileMetaData> <i32 LE footer len> "PAR1".
      class ParquetTableWriter
        MAGIC = 'PAR1'

        # Parquet `FieldRepetitionType`
        REP_REQUIRED = 0
        REP_OPTIONAL = 1
        # Parquet `ConvertedType`
        CONVERTED_UTF8 = 0
        # Parquet `Encoding`
        ENC_PLAIN = 0
        ENC_RLE = 3
        # Parquet `CompressionCodec`
        CODEC_UNCOMPRESSED = 0

        # @param path [String] output file path
        # @param schema [Array<Hash>] column definitions (see class docs)
        # @param flush_bytes [Integer] approx buffered bytes before an auto row-group flush
        # @param max_rows [Integer] max buffered rows before an auto flush
        def initialize(path, schema, flush_bytes: 64 * 1024 * 1024, max_rows: 200_000)
          @path = path
          @schema = schema
          @flush_bytes = flush_bytes
          @max_rows = max_rows

          @io = File.open(path, 'wb')
          @io.write(MAGIC)
          @pos = MAGIC.bytesize

          @row_groups = [] # accumulated row-group metadata for the footer
          @total_rows = 0
          reset_buffers
        end

        # Appends one row. `cells` length/order must match the schema.
        def add_row(*cells)
          raise ArgumentError, "expected #{@schema.length} cells, got #{cells.length}" if cells.length != @schema.length

          cells.each_with_index do |v, i|
            @columns[i] << v
            est = @schema[i][:type]
            @buffered_bytes += if est == :string
                                 v.nil? ? 1 : v.to_s.bytesize + 5
                               elsif est == :bytes
                                 v.nil? ? 1 : v.bytesize + 5
                               else
                                 8
                               end
          end
          @buffered_rows += 1
          flush if @buffered_rows >= @max_rows || @buffered_bytes >= @flush_bytes
        end

        # Writes the buffered rows as one row group (no-op when empty).
        def flush
          return if @buffered_rows.zero?

          chunks = []
          total_byte_size = 0
          @schema.each_with_index do |col, i|
            body = ColumnWriter.page_body(col[:type], col[:optional], @columns[i])
            page = ColumnWriter.data_page(@buffered_rows, body)
            offset = @pos
            @io.write(page)
            @pos += page.bytesize
            total_byte_size += page.bytesize
            chunks << { col: col, offset: offset, size: page.bytesize, num_values: @buffered_rows }
          end
          @row_groups << { chunks: chunks, num_rows: @buffered_rows, total_byte_size: total_byte_size }
          @total_rows += @buffered_rows
          reset_buffers
        end

        # Flushes any remaining rows, writes the footer, and closes the file.
        def complete
          return if @completed

          @completed = true
          flush
          footer = build_footer
          @io.write(footer)
          @io.write([footer.bytesize].pack('V'))
          @io.write(MAGIC)
          @io.close
        end

        # @return [Integer] total rows written so far (excludes the current buffer)
        attr_reader :total_rows

        private

        def reset_buffers
          @columns = Array.new(@schema.length) { [] }
          @buffered_rows = 0
          @buffered_bytes = 0
        end

        def build_footer
          tc = ThriftCompact.new
          tc.struct_begin # FileMetaData
          tc.i32_field(1, 1) # version

          # field 2: schema = [root, *leaves]
          tc.list_field_header(2, @schema.length + 1, ThriftCompact::T_STRUCT)
          write_root_schema_element(tc)
          @schema.each { |col| write_leaf_schema_element(tc) { col } }

          tc.i64_field(3, @total_rows) # num_rows

          # field 4: row_groups
          tc.list_field_header(4, @row_groups.length, ThriftCompact::T_STRUCT)
          @row_groups.each { |rg| write_row_group(tc, rg) }

          tc.binary_field(6, 'speckle-sketchup parquet writer')
          tc.struct_end
          tc.bytes
        end

        def write_root_schema_element(tc)
          tc.struct_begin
          tc.binary_field(4, 'schema')
          tc.i32_field(5, @schema.length) # num_children
          tc.struct_end
        end

        def write_leaf_schema_element(tc)
          col = yield
          tc.struct_begin
          tc.i32_field(1, ColumnWriter.physical_type(col[:type])) # type
          tc.i32_field(3, col[:optional] ? REP_OPTIONAL : REP_REQUIRED) # repetition_type
          tc.binary_field(4, col[:name]) # name
          tc.i32_field(6, CONVERTED_UTF8) if col[:type] == :string # converted_type
          tc.struct_end
        end

        def write_row_group(tc, rg)
          tc.struct_begin # RowGroup
          # field 1: columns = list<ColumnChunk>
          tc.list_field_header(1, rg[:chunks].length, ThriftCompact::T_STRUCT)
          rg[:chunks].each { |chunk| write_column_chunk(tc, chunk) }
          tc.i64_field(2, rg[:total_byte_size]) # total_byte_size
          tc.i64_field(3, rg[:num_rows]) # num_rows
          tc.struct_end
        end

        def write_column_chunk(tc, chunk)
          tc.struct_begin # ColumnChunk
          tc.i64_field(2, chunk[:offset]) # file_offset
          tc.struct_begin_field(3) # meta_data = ColumnMetaData
          col = chunk[:col]
          tc.i32_field(1, ColumnWriter.physical_type(col[:type])) # type
          tc.list_field_header(2, 2, ThriftCompact::T_I32) # encodings
          tc.write_zigzag(ENC_PLAIN)
          tc.write_zigzag(ENC_RLE)
          tc.list_field_header(3, 1, ThriftCompact::T_BINARY) # path_in_schema
          tc.write_binary(col[:name])
          tc.i32_field(4, CODEC_UNCOMPRESSED) # codec
          tc.i64_field(5, chunk[:num_values]) # num_values
          tc.i64_field(6, chunk[:size]) # total_uncompressed_size
          tc.i64_field(7, chunk[:size]) # total_compressed_size
          tc.i64_field(9, chunk[:offset]) # data_page_offset
          tc.struct_end # ColumnMetaData
          tc.struct_end # ColumnChunk
        end
      end
    end
  end
end
