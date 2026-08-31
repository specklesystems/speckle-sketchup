# frozen_string_literal: true

require_relative 'thrift_compact'

module SpeckleConnector3
  module Artifacts
    module Parquet
      # Encodes one column chunk's single DATA_PAGE (v1) for a flat (non-nested)
      # column: PLAIN values, plus RLE-encoded definition levels for OPTIONAL
      # columns (max def level 1; required columns store no levels). Repetition
      # levels are never stored (path length 1).
      #
      # Physical types handled: :int32, :double, :boolean, :string, :bytes
      # (:string/:bytes are both BYTE_ARRAY; :string is annotated UTF8 by the table
      # writer's schema, not here).
      module ColumnWriter
        # Parquet physical type ids (parquet.thrift `Type`).
        PHYS = {
          boolean: 0,
          int32: 1,
          int64: 2,
          double: 5,
          byte_array: 6
        }.freeze

        # Maps our column type symbols to the Parquet physical type id.
        def self.physical_type(type)
          case type
          when :int32 then PHYS[:int32]
          when :double then PHYS[:double]
          when :boolean then PHYS[:boolean]
          when :string, :bytes then PHYS[:byte_array]
          else raise ArgumentError, "unknown column type #{type.inspect}"
          end
        end

        # Builds the page body (levels + PLAIN values) for one column.
        # @param type [Symbol] column physical type
        # @param optional [Boolean] whether the column is nullable (def levels emitted)
        # @param values [Array] one entry per row (nil = null; only allowed when optional)
        # @return [String] the (uncompressed) page body bytes
        def self.page_body(type, optional, values)
          body = ''.b
          if optional
            def_levels = values.map { |v| v.nil? ? 0 : 1 }
            rle = rle_levels(def_levels)
            body << [rle.bytesize].pack('V') # v1 data page: 4-byte LE length prefix
            body << rle
            present = values.reject(&:nil?)
          else
            present = values
          end
          body << plain(type, present)
          body
        end

        # PLAIN encoding of the present (non-null) values.
        def self.plain(type, present)
          case type
          when :int32
            present.map { |v| v.to_i }.pack('l<*')
          when :double
            present.map { |v| v.to_f }.pack('E*')
          when :boolean
            bitpack_bools(present)
          when :string, :bytes
            out = ''.b
            present.each do |v|
              b = type == :string ? v.to_s.encode('UTF-8').b : v.b
              out << [b.bytesize].pack('V') << b
            end
            out
          else
            raise ArgumentError, "unknown column type #{type.inspect}"
          end
        end

        # PLAIN boolean: 1 bit per value, LSB-first, padded to whole bytes.
        def self.bitpack_bools(present)
          out = ''.b
          byte = 0
          nbits = 0
          present.each do |v|
            byte |= (1 << nbits) if v
            nbits += 1
            if nbits == 8
              out << byte.chr
              byte = 0
              nbits = 0
            end
          end
          out << byte.chr if nbits.positive?
          out
        end

        # RLE/bit-pack hybrid for 0/1 definition levels (bit width 1), emitted as
        # plain RLE runs of consecutive equal levels. Each run: varint(len << 1)
        # then the level value in ceil(bitWidth/8) = 1 byte.
        def self.rle_levels(levels)
          out = ''.b
          i = 0
          n = levels.length
          while i < n
            v = levels[i]
            run = 1
            run += 1 while (i + run) < n && levels[i + run] == v
            out << uvarint(run << 1)
            out << v.chr
            i += run
          end
          out
        end

        # Unsigned LEB128 varint.
        def self.uvarint(value)
          out = ''.b
          v = value
          loop do
            if (v & ~0x7F).zero?
              out << v.chr
              break
            end
            out << (((v & 0x7F) | 0x80)).chr
            v >>= 7
          end
          out
        end

        # Wraps a page body in a DATA_PAGE (v1) `PageHeader` thrift + the body.
        # @return [String] header thrift bytes followed by the page body
        def self.data_page(num_values, body)
          tc = ThriftCompact.new
          tc.struct_begin # PageHeader
          tc.i32_field(1, 0)               # type = DATA_PAGE (0)
          tc.i32_field(2, body.bytesize)   # uncompressed_page_size
          tc.i32_field(3, body.bytesize)   # compressed_page_size (UNCOMPRESSED codec)
          tc.struct_begin_field(5)         # data_page_header (struct field 5)
          tc.i32_field(1, num_values)      # num_values
          tc.i32_field(2, 0)               # encoding = PLAIN (0)
          tc.i32_field(3, 3)               # definition_level_encoding = RLE (3)
          tc.i32_field(4, 3)               # repetition_level_encoding = RLE (3)
          tc.struct_end                    # end data_page_header
          tc.struct_end                    # end PageHeader
          tc.bytes + body
        end
      end
    end
  end
end
