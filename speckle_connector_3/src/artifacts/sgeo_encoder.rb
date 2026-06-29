# frozen_string_literal: true

require 'zlib'

module SpeckleConnector3
  module Artifacts
    # SGEO v1 binary geometry encoder — a pure-Ruby mirror of the SDK's
    # `Speckle.Objects.Utils.SgeoEncoder` / `SgeoFormat`. One opaque blob per
    # geometry buffer: a 16-byte little-endian header + a per-primitive body.
    #
    # SketchUp only emits **Mesh (0)** and **Line (1)**; the other nine primitives
    # in the SDK are intentionally not ported.
    #
    # Header (16 bytes, LE):
    #   0x00  4  magic "SGEO"
    #   0x04  1  version = 1
    #   0x05  1  primitive_type
    #   0x06  2  flags (uint16)
    #   0x08  2  units_code (uint16)
    #   0x0A  2  reserved = 0
    #   0x0C  4  crc32 of the body bytes (zlib/IEEE)
    #   0x10  …  body
    module SgeoEncoder
      MAGIC = 'SGEO'
      VERSION = 1
      HEADER_SIZE = 16

      # primitive type codes
      TYPE_MESH = 0
      TYPE_LINE = 1

      # SgeoFlags bitfield
      FLAG_HAS_NORMALS = 1 << 4
      FLAG_HAS_UVS = 1 << 5
      FLAG_HAS_COLORS = 1 << 6

      # Units string -> uint16 code (mirrors Units.GetEncodingFromUnit; unknown -> 0).
      UNIT_CODES = {
        'mm' => 1, 'cm' => 2, 'm' => 3, 'km' => 4,
        'in' => 5, 'ft' => 6, 'yd' => 7, 'mi' => 8
      }.freeze

      module_function

      def unit_code(units)
        UNIT_CODES[units] || 0
      end

      # Encodes a mesh blob.
      # @param vertices [Array<Float>] flat xyz triples (length multiple of 3)
      # @param faces [Array<Integer>] Speckle face stream ([n, i0..in-1, ...])
      # @param units [String]
      # @param normals [Array<Float>] optional flat xyz vertex normals
      # @param uvs [Array<Float>] optional flat uv pairs
      # @param colors [Array<Integer>] optional per-vertex ARGB ints
      # @return [String] the SGEO blob (binary String)
      def encode_mesh(vertices, faces, units, normals: [], uvs: [], colors: [])
        raise ArgumentError, 'Mesh.vertices length must be a multiple of 3.' unless (vertices.length % 3).zero?

        flags = 0
        flags |= FLAG_HAS_NORMALS unless normals.empty?
        flags |= FLAG_HAS_UVS unless uvs.empty?
        flags |= FLAG_HAS_COLORS unless colors.empty?

        body = ''.b
        body << [vertices.length / 3].pack('V')
        body << [faces.length].pack('V')
        body << vertices.pack('E*')
        body << faces.pack('l<*')
        unless normals.empty?
          pad8(body)
          body << normals.pack('E*')
        end
        unless uvs.empty?
          pad8(body)
          body << uvs.pack('E*')
        end
        body << colors.pack('l<*') unless colors.empty?

        assemble(TYPE_MESH, flags, units, body)
      end

      # Encodes a line blob.
      # @param start_pt [Array<Float>] [x, y, z]
      # @param end_pt [Array<Float>] [x, y, z]
      def encode_line(start_pt, end_pt, units, domain_start: 0.0, domain_end: 1.0)
        body = ''.b
        body << [domain_start, domain_end].pack('E2')
        body << start_pt.pack('E3')
        body << end_pt.pack('E3')
        assemble(TYPE_LINE, 0, units, body)
      end

      # Builds the 16-byte header + body, filling the CRC32 over the body.
      def assemble(type, flags, units, body)
        header = ''.b
        header << MAGIC.b                       # 0x00 magic
        header << [VERSION].pack('C')            # 0x04 version
        header << [type].pack('C')               # 0x05 primitive_type
        header << [flags].pack('v')              # 0x06 flags (uint16 LE)
        header << [unit_code(units)].pack('v')   # 0x08 units_code (uint16 LE)
        header << [0].pack('v')                  # 0x0A reserved
        header << [Zlib.crc32(body)].pack('V')   # 0x0C crc32 of body
        header + body
      end

      # Pads `body` (in place) with zero bytes to the next 8-byte boundary.
      def pad8(body)
        pad = (-body.bytesize) % 8
        body << ("\x00".b * pad) if pad.positive?
        body
      end
    end
  end
end
