# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    module Parquet
      # Reads the Thrift **Compact Protocol** — the inverse of {ThriftCompact}.
      # Generic: a struct decodes to a Hash{field_id => value}, lists to arrays,
      # nested structs recurse. Enough to parse Parquet `FileMetaData` / `PageHeader`.
      class ThriftCompactReader
        def initialize(bytes, pos = 0)
          @b = bytes
          @pos = pos
        end

        # @return [Integer] current byte offset (used to find a page body after its header)
        attr_reader :pos

        # Reads a struct into { field_id => value }, terminated by the STOP byte.
        def read_struct
          fields = {}
          last = 0
          loop do
            header = next_byte
            break if header.zero? # STOP

            type = header & 0x0F
            delta = (header >> 4) & 0x0F
            field_id = delta.zero? ? read_zigzag : last + delta
            last = field_id
            fields[field_id] = read_value(type)
          end
          fields
        end

        private

        def read_value(type)
          case type
          when 0x01 then true            # BOOL_TRUE
          when 0x02 then false           # BOOL_FALSE
          when 0x03 then next_byte       # BYTE
          when 0x04, 0x05, 0x06 then read_zigzag # I16 / I32 / I64
          when 0x07 then read_double
          when 0x08 then read_binary
          when 0x09, 0x0A then read_list # LIST / SET
          when 0x0C then read_struct     # STRUCT
          else raise "unsupported thrift compact type #{type}"
          end
        end

        def read_list
          header = next_byte
          size = (header >> 4) & 0x0F
          size = read_varint if size == 15
          elem_type = header & 0x0F
          Array.new(size) { read_value(elem_type) }
        end

        def next_byte
          v = @b.getbyte(@pos)
          @pos += 1
          v
        end

        def read_varint
          result = 0
          shift = 0
          loop do
            byte = next_byte
            result |= (byte & 0x7F) << shift
            break if (byte & 0x80).zero?

            shift += 7
          end
          result
        end

        def read_zigzag
          n = read_varint
          (n >> 1) ^ -(n & 1)
        end

        def read_binary
          len = read_varint
          s = @b.byteslice(@pos, len)
          @pos += len
          s
        end

        def read_double
          s = @b.byteslice(@pos, 8)
          @pos += 8
          s.unpack1('E')
        end
      end
    end
  end
end
