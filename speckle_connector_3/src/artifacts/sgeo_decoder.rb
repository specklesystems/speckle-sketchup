# frozen_string_literal: true

require 'zlib'
require_relative 'sgeo_encoder'

module SpeckleConnector3
  module Artifacts
    # Decodes SGEO v1 blobs back into geometry — the inverse of {SgeoEncoder}.
    # Mesh + Line decode to their native shapes; every other primitive
    # (Polyline / Polycurve / Curve / Arc / Circle / Spiral / Ellipse / Box / Points)
    # decodes to a `:polyline` point list, which receive turns into SketchUp edges —
    # so a Revit/other-connector bundle's full geometry comes in (SketchUp has no
    # native NURBS; curves carry a baked display polyline, used here).
    module SgeoDecoder
      CODE_UNITS = SgeoEncoder::UNIT_CODES.invert.freeze
      FLAG_CLOSED = 1 << 1
      ARC_SEGMENTS = 32

      module_function

      # @param blob [String] an SGEO binary blob
      # @return [Hash] :mesh {vertices,faces,...} | :line {start,end,...} |
      #   :polyline {points:[[x,y,z]...], closed:} | :unsupported {primitive:}
      def decode(blob)
        b = blob.b
        raise ArgumentError, 'not an SGEO blob' unless b.byteslice(0, 4) == SgeoEncoder::MAGIC
        raise ArgumentError, "unsupported SGEO version #{b.getbyte(4)}" unless b.getbyte(4) == SgeoEncoder::VERSION

        type = b.getbyte(5)
        flags = b.byteslice(6, 2).unpack1('v')
        units = CODE_UNITS[b.byteslice(8, 2).unpack1('v')] || 'none'
        # Header CRC (0x0C) is a canonical zlib/IEEE CRC-32 of the body across all
        # producers (SDK/Revit/specklepy now match Zlib.crc32) — but we don't verify
        # it: magic + version above are the guards, and skipping keeps us lenient to
        # any stray blob written before the SDK's 0xEDB88820->0xEDB88320 CRC fix.
        body = b.byteslice(SgeoEncoder::HEADER_SIZE..) || ''.b

        decode_body(type, flags, units, body)
      end

      def decode_body(type, flags, units, body)
        closed = (flags & FLAG_CLOSED) != 0
        case type
        when 0 then decode_mesh(body, flags, units)              # Mesh
        when 1 then decode_line(body, units)                     # Line
        when 2 then polyline(read_points(body, 0), units, closed) # Polyline
        when 3 then decode_polycurve(body, units, closed)        # Polycurve
        when 4, 9 then polyline(read_points(body, 0), units, closed) # Curve/Spiral: leading display polyline
        when 5 then decode_arc(body, units)                      # Arc
        when 6 then decode_circle(body, units)                   # Circle
        when 7 then polyline(read_points(body, 0), units, false) # Points
        else { type: :unsupported, primitive: type, units: units }
        end
      end

      # ── mesh / line ───────────────────────────────────────────────────

      def decode_mesh(body, flags, units)
        vcount = body.byteslice(0, 4).unpack1('V')
        fcount = body.byteslice(4, 4).unpack1('V')
        pos = 8
        vertices = body.byteslice(pos, vcount * 3 * 8).unpack('E*')
        pos += vcount * 3 * 8
        faces = body.byteslice(pos, fcount * 4).unpack('l<*')
        pos += fcount * 4

        normals = []
        uvs = []
        colors = []
        if (flags & SgeoEncoder::FLAG_HAS_NORMALS) != 0
          pos = pad8(pos)
          normals = body.byteslice(pos, vcount * 3 * 8).unpack('E*')
          pos += vcount * 3 * 8
        end
        if (flags & SgeoEncoder::FLAG_HAS_UVS) != 0
          pos = pad8(pos)
          uvs = body.byteslice(pos, vcount * 2 * 8).unpack('E*')
          pos += vcount * 2 * 8
        end
        colors = body.byteslice(pos, vcount * 4).unpack('l<*') if (flags & SgeoEncoder::FLAG_HAS_COLORS) != 0

        { type: :mesh, vertices: vertices, faces: faces, units: units, normals: normals, uvs: uvs, colors: colors,
          hard_edges: (flags & SgeoEncoder::FLAG_HARD_EDGES) != 0 }
      end

      def decode_line(body, units)
        domain_start, domain_end, sx, sy, sz, ex, ey, ez = body.byteslice(0, 8 * 8).unpack('E8')
        { type: :line, start: [sx, sy, sz], end: [ex, ey, ez], units: units, domain: [domain_start, domain_end] }
      end

      # ── curve family (-> polyline points) ─────────────────────────────

      # A polyline body: u32 count, u32 pad, then count xyz doubles. Returns the
      # points array and the byte offset just past them (8-aligned).
      def read_points(body, pos)
        count = body.byteslice(pos, 4).unpack1('V')
        pos += 8
        coords = body.byteslice(pos, count * 3 * 8).unpack('E*')
        coords.each_slice(3).to_a
      end

      def decode_polycurve(body, units, closed)
        seg_count = body.byteslice(0, 4).unpack1('V')
        pos = 8
        points = []
        seg_count.times do
          blob_len = body.byteslice(pos, 4).unpack1('V')
          pos += 8
          seg = decode(body.byteslice(pos, blob_len))
          points.concat(seg[:points]) if seg[:type] == :polyline
          points.concat(line_points(seg)) if seg[:type] == :line
          pos += blob_len
          pos = pad8(pos)
        end
        polyline(points, units, closed)
      end

      def decode_arc(body, units)
        # plane(12 doubles: origin, normal, xdir, ydir), start(3), mid(3), end(3), domain(2)
        vals = body.byteslice(0, 23 * 8).unpack('E23')
        center = vals[0, 3]
        xdir = vals[6, 3]
        ydir = vals[9, 3]
        start_pt = vals[12, 3]
        mid_pt = vals[15, 3]
        end_pt = vals[18, 3]
        polyline(tessellate_arc(center, xdir, ydir, start_pt, mid_pt, end_pt), units, false)
      end

      def decode_circle(body, units)
        radius = body.byteslice(0, 8).unpack1('E')
        plane = body.byteslice(24, 12 * 8).unpack('E12') # after radius + 2 domain doubles
        center = plane[0, 3]
        xdir = plane[6, 3]
        ydir = plane[9, 3]
        points = (0...ARC_SEGMENTS).map do |i|
          a = 2 * Math::PI * i / ARC_SEGMENTS
          axis_point(center, xdir, ydir, radius, a)
        end
        polyline(points, units, true)
      end

      # ── helpers ───────────────────────────────────────────────────────

      def polyline(points, units, closed)
        { type: :polyline, points: points, units: units, closed: closed }
      end

      def line_points(line)
        [line[:start], line[:end]]
      end

      def axis_point(center, xdir, ydir, radius, angle)
        c = Math.cos(angle) * radius
        s = Math.sin(angle) * radius
        [
          center[0] + c * xdir[0] + s * ydir[0],
          center[1] + c * xdir[1] + s * ydir[1],
          center[2] + c * xdir[2] + s * ydir[2]
        ]
      end

      # Samples the arc through start/mid/end using the plane basis at `center`.
      def tessellate_arc(center, xdir, ydir, start_pt, mid_pt, end_pt)
        a0 = plane_angle(center, xdir, ydir, start_pt)
        am = plane_angle(center, xdir, ydir, mid_pt)
        a1 = plane_angle(center, xdir, ydir, end_pt)
        radius = distance(center, start_pt)
        sweep = arc_sweep(a0, am, a1)
        (0..ARC_SEGMENTS).map { |i| axis_point(center, xdir, ydir, radius, a0 + sweep * i / ARC_SEGMENTS) }
      end

      def plane_angle(center, xdir, ydir, point)
        vx = point[0] - center[0]
        vy = point[1] - center[1]
        vz = point[2] - center[2]
        Math.atan2(dot([vx, vy, vz], ydir), dot([vx, vy, vz], xdir))
      end

      # Total signed sweep a0 -> a1 that passes through am (handles wrap + direction).
      def arc_sweep(a0, am, a1)
        norm = ->(x) { x -= 2 * Math::PI while x > Math::PI; x += 2 * Math::PI while x < -Math::PI; x }
        d1 = norm.call(am - a0)
        d2 = norm.call(a1 - am)
        total = d1 + d2
        total += 2 * Math::PI if total.positive? && norm.call(a1 - a0) < 0 && d1 < 0
        total
      end

      def dot(a, b)
        a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
      end

      def distance(a, b)
        Math.sqrt((a[0] - b[0])**2 + (a[1] - b[1])**2 + (a[2] - b[2])**2)
      end

      def pad8(pos)
        pos + ((-pos) % 8)
      end
    end
  end
end
