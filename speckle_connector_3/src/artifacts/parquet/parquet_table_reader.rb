# frozen_string_literal: true

require_relative 'thrift_compact_reader'

module SpeckleConnector3
  module Artifacts
    module Parquet
      # Reads a flat UNCOMPRESSED Parquet file written by {ParquetTableWriter} back
      # into rows. Handles exactly what we emit: PLAIN values, RLE definition levels
      # for OPTIONAL columns, one or more row groups, codec UNCOMPRESSED, physical
      # types int32 / double / boolean / byte_array. (Compressed / dictionary-encoded
      # files from other producers need the _duckdb native ext instead.)
      module ParquetTableReader
        MAGIC = 'PAR1'

        # Parquet physical type ids
        PHYS_BOOLEAN = 0
        PHYS_INT32 = 1
        PHYS_DOUBLE = 5
        PHYS_BYTE_ARRAY = 6

        # Parquet CompressionCodec.UNCOMPRESSED / Encoding values we can decode.
        CODEC_UNCOMPRESSED = 0
        SUPPORTED_ENCODINGS = [0, 3, 4].freeze # PLAIN, RLE, BIT_PACKED

        # Raised when a file uses compression / encodings this pure-Ruby reader does
        # not implement (e.g. a Revit bundle: ZSTD + DELTA_BINARY_PACKED). Receiving
        # non-SketchUp versions needs the _duckdb native ext.
        class UnsupportedParquetError < StandardError; end

        module_function

        # @param path [String]
        # @return [Hash] { columns: [name,...], rows: [[v,...], ...] }
        def read(path)
          bytes = File.binread(path).b
          unless bytes.byteslice(0, 4) == MAGIC && bytes.byteslice(-4, 4) == MAGIC
            raise ArgumentError, "#{File.basename(path)}: not a parquet file"
          end

          footer_len = bytes.byteslice(-8, 4).unpack1('V')
          footer_start = bytes.bytesize - 8 - footer_len
          meta = ThriftCompactReader.new(bytes, footer_start).read_struct

          cols = column_defs(meta[2]) # field 2: schema list ([root, *leaves])
          rows = []
          (meta[4] || []).each do |row_group| # field 4: row_groups
            chunks = row_group[1] # field 1: columns
            num_rows = row_group[3] # field 3: num_rows
            col_values = chunks.each_with_index.map do |chunk, i|
              read_column(bytes, chunk, cols[i])
            end
            num_rows.times do |r|
              rows << cols.each_index.map { |c| col_values[c][r] }
            end
          end

          { columns: cols.map { |c| c[:name] }, rows: rows }
        end

        # Convenience: rows as an array of Hash{column_name => value}.
        def read_hashes(path)
          t = read(path)
          t[:rows].map { |row| t[:columns].each_with_index.to_h { |name, i| [name, row[i]] } }
        end

        # ── internals ─────────────────────────────────────────────────────

        # SchemaElement: 1 type, 3 repetition_type, 4 name, 6 converted_type(UTF8=0).
        def column_defs(schema)
          schema.drop(1).map do |se|
            { name: se[4], phys: se[1], optional: se[3] == 1, utf8: se[6] == 0 }
          end
        end

        # ColumnChunk: 3 meta_data{ 2 encodings, 4 codec, 5 num_values, 9 data_page_offset }.
        def read_column(bytes, chunk, col)
          cm = chunk[3]
          ensure_supported(cm)
          offset = cm[9] || chunk[2]
          reader = ThriftCompactReader.new(bytes, offset)
          page_header = reader.read_struct
          body_len = page_header[3] # compressed_page_size (== uncompressed for us)
          dph = page_header[5] # data_page_header
          num_values = dph[1]
          body = bytes.byteslice(reader.pos, body_len)
          decode_page(body, col, num_values)
        end

        # Bails clearly if the column chunk isn't UNCOMPRESSED + PLAIN/RLE/BIT_PACKED.
        def ensure_supported(cm)
          if cm.nil?
            raise UnsupportedParquetError,
                  'Parquet column has no inline metadata — this reader only handles bundles we wrote. ' \
                  'Receiving Revit/other-connector versions needs the _duckdb native ext.'
          end
          codec = cm[4] || CODEC_UNCOMPRESSED
          encodings = cm[2] || []
          return if codec == CODEC_UNCOMPRESSED && encodings.all? { |e| SUPPORTED_ENCODINGS.include?(e) }

          raise UnsupportedParquetError,
                "Parquet uses compression/encoding the pure-Ruby reader can't decode (codec=#{codec}, " \
                "encodings=#{encodings.inspect}; e.g. Revit's ZSTD + DELTA_BINARY_PACKED). " \
                'Receiving non-SketchUp versions needs the _duckdb native ext.'
        end

        def decode_page(body, col, num_values)
          if col[:optional]
            level_len = body.byteslice(0, 4).unpack1('V')
            levels = decode_def_levels(body, 4, level_len, num_values)
            present = levels.count(1)
            values = decode_plain(body, 4 + level_len, col, present)
            vi = -1
            levels.map { |lv| lv == 1 ? values[vi += 1] : nil }
          else
            decode_plain(body, 0, col, num_values)
          end
        end

        # RLE/bit-pack hybrid for 0/1 definition levels (bit width 1).
        def decode_def_levels(body, pos, len, num_values)
          levels = []
          stop = pos + len
          while pos < stop && levels.length < num_values
            header, pos = read_uvarint(body, pos)
            if (header & 1).zero? # RLE run
              run = header >> 1
              value = body.getbyte(pos)
              pos += 1
              run.times { levels << value }
            else # bit-packed run (width 1: 8 values per byte, LSB first)
              groups = header >> 1
              (groups * 8).times do |i|
                levels << ((body.getbyte(pos + (i / 8)) >> (i % 8)) & 1)
              end
              pos += groups
            end
          end
          levels.first(num_values)
        end

        def decode_plain(body, pos, col, count)
          case col[:phys]
          when PHYS_INT32
            body.byteslice(pos, count * 4).unpack('l<*')
          when PHYS_DOUBLE
            body.byteslice(pos, count * 8).unpack('E*')
          when PHYS_BOOLEAN
            Array.new(count) { |i| ((body.getbyte(pos + (i / 8)) >> (i % 8)) & 1) == 1 }
          when PHYS_BYTE_ARRAY
            out = []
            count.times do
              len = body.byteslice(pos, 4).unpack1('V')
              pos += 4
              s = body.byteslice(pos, len)
              pos += len
              out << (col[:utf8] ? s.dup.force_encoding('UTF-8') : s)
            end
            out
          else
            raise "unsupported physical type #{col[:phys]}"
          end
        end

        def read_uvarint(body, pos)
          result = 0
          shift = 0
          loop do
            byte = body.getbyte(pos)
            pos += 1
            result |= (byte & 0x7F) << shift
            break if (byte & 0x80).zero?

            shift += 7
          end
          [result, pos]
        end
      end
    end
  end
end
