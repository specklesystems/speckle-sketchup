# frozen_string_literal: true

module SpeckleConnector3
  module Artifacts
    module Parquet
      # Minimal Thrift **Compact Protocol** writer — only the pieces the Parquet
      # `FileMetaData` / `PageHeader` thrift structures need (struct/field headers,
      # i32/i64 zigzag varints, binary, bool, and homogeneous lists).
      #
      # Compact protocol rules implemented here:
      # - Field headers use a 4-bit delta over the previous field id in the same
      #   struct: `(delta << 4) | type` when 1 <= delta <= 15, else a `type` byte
      #   followed by the zigzag-varint field id.
      # - Structs are a sequence of fields terminated by a STOP byte (0x00).
      # - bool fields encode their value in the type nibble (BOOL_TRUE / BOOL_FALSE).
      # - i16/i32/i64 are zigzag-varint encoded; binary is varint length + bytes.
      # - list header: `(size << 4) | elem_type` when size < 15, else `0xF | ...`
      #   (0xF0 | elem_type) then varint size; elements follow.
      class ThriftCompact
        # compact field/element type ids
        T_BOOL_TRUE = 0x01
        T_BOOL_FALSE = 0x02
        T_BYTE = 0x03
        T_I16 = 0x04
        T_I32 = 0x05
        T_I64 = 0x06
        T_DOUBLE = 0x07
        T_BINARY = 0x08
        T_LIST = 0x09
        T_SET = 0x0A
        T_MAP = 0x0B
        T_STRUCT = 0x0C

        def initialize
          @buf = ''.b
          @field_stack = []
          @last_field = 0
        end

        # @return [String] the encoded bytes (binary-encoded String)
        def bytes
          @buf
        end

        def struct_begin
          @field_stack.push(@last_field)
          @last_field = 0
        end

        # Writes a STRUCT-typed field header, then opens the nested struct.
        # Pair with a matching `struct_end`.
        def struct_begin_field(field_id)
          field_header(field_id, T_STRUCT)
          struct_begin
        end

        def struct_end
          @buf << "\x00".b # STOP
          @last_field = @field_stack.pop || 0
        end

        def i32_field(field_id, value)
          field_header(field_id, T_I32)
          write_zigzag(value)
        end

        def i64_field(field_id, value)
          field_header(field_id, T_I64)
          write_zigzag(value)
        end

        def double_field(field_id, value)
          field_header(field_id, T_DOUBLE)
          @buf << [value].pack('E') # compact protocol: little-endian IEEE-754
        end

        def bool_field(field_id, value)
          field_header(field_id, value ? T_BOOL_TRUE : T_BOOL_FALSE)
        end

        # UTF-8 / binary value (same wire shape; the Parquet schema marks UTF8).
        def binary_field(field_id, str)
          field_header(field_id, T_BINARY)
          write_binary(str)
        end

        # Writes a field header for a list and returns; caller writes `size` elements.
        def list_field_header(field_id, size, elem_type)
          field_header(field_id, T_LIST)
          list_header(size, elem_type)
        end

        # A bare list (e.g. a list element that is itself a list) — no field header.
        def list_header(size, elem_type)
          if size < 15
            @buf << ((size << 4) | elem_type).chr
          else
            @buf << (0xF0 | elem_type).chr
            write_varint(size)
          end
        end

        # A bare binary value (e.g. a string element inside a list).
        def write_binary(str)
          b = str.to_s.b
          write_varint(b.bytesize)
          @buf << b
        end

        # A bare zigzag varint (e.g. an i32 element inside a list).
        def write_zigzag(value)
          zz = (value << 1) ^ (value >> 63)
          write_varint(zz & 0xFFFFFFFFFFFFFFFF)
        end

        private

        def field_header(field_id, type)
          delta = field_id - @last_field
          if delta.positive? && delta <= 15
            @buf << ((delta << 4) | type).chr
          else
            @buf << type.chr
            write_zigzag(field_id)
          end
          @last_field = field_id
        end

        def write_varint(value)
          v = value
          loop do
            if (v & ~0x7F).zero?
              @buf << v.chr
              break
            end
            @buf << (((v & 0x7F) | 0x80)).chr
            v >>= 7
          end
        end
      end
    end
  end
end
