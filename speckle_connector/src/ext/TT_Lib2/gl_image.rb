#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'bezier.rb'
require_relative 'geom3d.rb'

# @note Alpha stage. Very likely to be subject to change!
#
# Read .gli file into an array of drawing instructions.
# The instructions is an array of method name and arguments.
#
#   POLYGON [10,0],[14,4],[6,4]
#   
#   becomes
#   
#   [ :draw2d, [ Point3d(10,0,0), Point3d(14,4,0), Point3d(6,4,0) ] ]
#
# This translate to arguments that is sent to the View object by using the
# .send method.
#
# = GL Image Format
#
# == Data Types
#
# <color>
# * red   <int>
# * green <int>
# * blue  <int>
# * alpha <int> (Default = 255)
#
# <point>
# * x <float>
# * y <float>
#
# == Instructions
#
# COLOR
# * color <color>
#
# WIDTH
# * width <int>
#
# STIPPLE
# * width <string>
#
# POINTS
# * type <string>
#     TRIANGLE_OPEN
#     TRIANGLE_FILLED
#     SQUARE_OPEN
#     SQUARE_FILLED
#     CIRCLE, O
#     DISC, *
#     PLUS, +
#     CROSS, X
# * size <int>
# * points <point>+
#
# LINES
# * points <point>+
#
# POLYLINE
# * points <point>+
#
# BEZIER
# * points <point>+
#
# LOOP
# * points <point>+
#
# ARC
# * center <point>
# * radius <float>
# * degrees <float>
# * segments <int>
# * start_angle <float> (Default = 0.0)
#
# CIRCLE
# * center <point>
# * radius <float>
# * segments <int>
#
# RECT
# * left <float>
# * top <float>
# * width <float>
# * height <float>
# * corner_radius <float> (Default = 0.0)
#
# POLYGON
# * points <point>+
#
# PIE
# * center <point>
# * radius <float>
# * degrees <float>
# * segments <int>
# * start_angle <float> (Default = 0.0)
#
# DISC
# * center <point>
# * radius <float>
# * segments <int>
#
# GRADIENT
# * left <float>
# * top <float>
# * width <float>
# * height <float>
# * steps <int>
# * horizontal <bool>
# * start_color <color>
# * end_color <color>
#
# @since 2.7.0

module SpeckleConnector
  class TT::GL_Image

    # http://www.songho.ca/opengl/index.html
    # http://www.songho.ca/opengl/gl_tessellation.html

    #   rescue TT::GL_Image::ParseError => e
    #
    # @since 2.7.0
    class ParseError < StandardError; end

    # @param [String] gl_image_file
    #
    # @since 2.7.0
    def initialize( gl_image_file )
      unless File.exist?( gl_image_file )
        raise( ArgumentError, "GL Image '#{gl_image_file}' not found." )
      end
      @file = gl_image_file
      @instructions = read_file( gl_image_file )
    end

    # @param [Sketchup::View] view
    # @param [Integer] x
    # @param [Integer] y
    #
    # @since 2.7.0
    def draw( view, x, y )
      # Reset viewport
      view.line_width = 1
      view.line_stipple = ''
      view.drawing_color = [0,0,0]
      # Process drawing instructions. Offset drawing by given coordinates.
      offset = Geom::Vector3d.new( x, y, 0 )
      for instruction in @instructions
        command, arguments = instruction
        positioned_arguments = arguments.map { |argument|
          if argument.is_a?( Geom::Point3d )
            argument.transform( offset )
          else
            argument
          end
        }
        begin
          view.send( command, *positioned_arguments )
        rescue => e
          p instruction
          raise( e )
        end
      end
    end

    # @return [String]
    # @since 2.7.0
    def inspect
      hex_id = TT.object_id_hex( self )
      "#<#{self.class.name}:#{hex_id}>"
    end

    private

    # @param [String] gl_image_file
    #
    # @return [Array]
    # @since 2.7.0
    def read_file( gl_image_file )
      offset = Geom::Point3d.new( 0, 0, 0 )
      odd_width = true # Default width = 1.0
      line_width = 1
      instructions = []
      File.open( gl_image_file, 'r' ) { |file|
        file.each_line { |line|
          #next if line[0,1] == '#'
          next if line[0] == 35 # Is it faster to check for single char like this?
          data = decode_line( line )
          command = data.shift
          case command
          when nil
            # Skip
          when 'OFFSET'
            x, y = data
            offset = Geom::Point3d.new( x, y, 0 )
          when 'COLOR'
            add_instruction( instructions, :drawing_color=, data )
          when 'WIDTH'
            line_width = data[0]
            odd_width = data[0] % 2 == 1
            add_instruction( instructions, :line_width=, data )
          when 'STIPPLE'
            add_instruction( instructions, :line_stipple=, data )
          when 'POINTS'
            style = data.shift
            size = data.shift
            r = size / 2
            points = []
            case style
            when 'SQUARE_OPEN'
              for point in data
                x1, y1 = point.to_a.map { |i| i - r }
                x2 = x1 + size
                y2 = y1 + size

                points << Geom::Point3d.new( x1, y1, 0 )
                points << Geom::Point3d.new( x2, y1, 0 )

                points << points.last
                points << Geom::Point3d.new( x2, y2, 0 )

                points << points.last
                points << Geom::Point3d.new( x1, y2, 0 )

                points << points.last
                points << points[-7]
              end
              adjust_points!( points, odd_width, offset )
              add_instruction( instructions, :draw2d, points, GL_LINES )
            when 'SQUARE_FILLED'
              for point in data
                x1, y1 = point.to_a.map { |i| i - r }
                x2 = x1 + size
                y2 = y1 + size
                points << Geom::Point3d.new( x1, y1, 0 )
                points << Geom::Point3d.new( x2, y1, 0 )
                points << Geom::Point3d.new( x2, y2, 0 )
                points << Geom::Point3d.new( x1, y2, 0 )
              end
              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_QUADS )
            when 'TRIANGLE_OPEN'
              for point in data
                x, y = point.to_a
                points << Geom::Point3d.new( x, y - r, 0 )
                points << Geom::Point3d.new( x - r, y + r, 0 )

                points << points.last
                points << Geom::Point3d.new( x + r, y + r, 0 )

                points << points.last
                points << points[-5]
              end
              adjust_points!( points, odd_width, offset )
              add_instruction( instructions, :draw2d, points, GL_LINES )
            when 'TRIANGLE_FILLED'
              for point in data
                x, y = point.to_a
                points << Geom::Point3d.new( x, y - r, 0 )
                points << Geom::Point3d.new( x - r, y + r, 0 )
                points << Geom::Point3d.new( x + r, y + r, 0 )
              end
              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_TRIANGLES )
            when 'PLUS', '+'
              for point in data
                x, y = point.to_a
                points << Geom::Point3d.new( x, y - r, 0 )
                points << Geom::Point3d.new( x, y + r, 0 )
                points << Geom::Point3d.new( x - r, y, 0 )
                points << Geom::Point3d.new( x + r, y, 0 )
              end
              adjust_points!( points, odd_width, offset )
              add_instruction( instructions, :draw2d, points, GL_LINES )
            when 'CROSS', 'X'
              for point in data
                x, y = point.to_a
                points << Geom::Point3d.new( x - r, y - r, 0 )
                points << Geom::Point3d.new( x + r, y + r, 0 )
                points << Geom::Point3d.new( x + r, y - r, 0 )
                points << Geom::Point3d.new( x - r, y + r, 0 )
              end
              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_LINES )
            when 'DISC', '*'
              for point in data
                points = TT::Geom3d.circle( point, Z_AXIS, r, 24 )
                adjust_points!( points, false, offset )
                add_instruction( instructions, :draw2d, points, GL_POLYGON )
              end
            when 'CIRCLE', 'O'
              for point in data
                points = TT::Geom3d.circle( point, Z_AXIS, r, 24 )
                adjust_points!( points, false, offset )
                add_instruction( instructions, :draw2d, points, GL_LINE_LOOP )
              end
            else
              raise( ParseError, "Invalid point style. (#{style})" )
            end
          when 'LINES'
            points = data
            adjust_points!( points, odd_width, offset )
            add_instruction( instructions, :draw2d, points, GL_LINES )
          when 'POLYLINE'
            points = data
            adjust_points!( points, odd_width, offset )
            add_instruction( instructions, :draw2d, points, GL_LINE_STRIP )
          when 'LOOP'
            points = data
            adjust_points!( points, odd_width, offset )
            add_instruction( instructions, :draw2d, points, GL_LINE_LOOP )
          when 'FRAME'
            x, y, w, h, r = data # X, Y, Width, Height, Radius
            o = line_width / 2.0 # Because of this - don't use off_width.
            points = []
            if r
              x_axis = X_AXIS.reverse
              z = Z_AXIS
              # Account for line width.
              ro = r - o
              # Top Left
              c = Geom::Point3d.new( x + r, y + r, 0 )
              arc = TT::Geom3d.arc( c, x_axis, z, ro, 0, 90.degrees, 8 )
              points.concat( arc )
              # Top Right
              c = Geom::Point3d.new( x + w - r, y + r, 0 )
              arc = TT::Geom3d.arc( c, x_axis, z, ro, 90.degrees, 180.degrees, 8 )
              points.concat( arc )
              # Bottom Right
              c = Geom::Point3d.new( x + w - r, y + h - r, 0 )
              arc = TT::Geom3d.arc( c, x_axis, z, ro, 180.degrees, 270.degrees, 8 )
              points.concat( arc )
              # Bottom Right
              c = Geom::Point3d.new( x + r, y + h - r, 0 )
              arc = TT::Geom3d.arc( c, x_axis, z, ro, 270.degrees, 360.degrees, 8 )
              points.concat( arc )

              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_LINE_LOOP )
            else
              points << Geom::Point3d.new( x,     y + o, 0 )
              points << Geom::Point3d.new( x + w, y + o, 0 )

              points << Geom::Point3d.new( x + w - o, y,     0 )
              points << Geom::Point3d.new( x + w - o, y + h, 0 )

              points << Geom::Point3d.new( x + w, y + h - o, 0 )
              points << Geom::Point3d.new( x,     y + h - o, 0 )

              points << Geom::Point3d.new( x + o, y + h, 0 )
              points << Geom::Point3d.new( x + o, y,     0 )

              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_LINES )
            end
          when 'BEZIER'
            points = TT::Geom3d::Bezier.points( data, 8 * data.size )
            adjust_points!( points, odd_width, offset )
            add_instruction( instructions, :draw2d, points, GL_LINE_STRIP )
          when 'ARC'
            center, radius, degrees, segments, start_angle = data
            start_angle = (start_angle) ? start_angle.degrees : 0.0
            end_angle = start_angle + degrees.degrees
            points = TT::Geom3d.arc( center, X_AXIS.reverse, Z_AXIS, radius, start_angle, end_angle, segments )
            adjust_points!( points, odd_width, offset )
            add_instruction( instructions, :draw2d, points, GL_LINE_STRIP )
          when 'CIRCLE'
            center, radius, segments = data
            points = TT::Geom3d.circle( center, Z_AXIS, radius, segments )
            adjust_points!( points, odd_width, offset )
            add_instruction( instructions, :draw2d, points, GL_LINE_LOOP )
          when 'RECT'
            x,y,w,h,r = data
            points = []
            if r
              x_axis = X_AXIS.reverse
              z = Z_AXIS
              # Top Left
              c = Geom::Point3d.new( x + r, y + r, 0 )
              points.concat( TT::Geom3d.arc( c, x_axis, z, r, 0, 90.degrees, 8 ) )
              # Top Right
              c = Geom::Point3d.new( x + w - r, y + r, 0 )
              points.concat( TT::Geom3d.arc( c, x_axis, z, r, 90.degrees, 180.degrees, 8 ) )
              # Bottom Right
              c = Geom::Point3d.new( x + w - r, y + h - r, 0 )
              points.concat( TT::Geom3d.arc( c, x_axis, z, r, 180.degrees, 270.degrees, 8 ) )
              # Bottom Right
              c = Geom::Point3d.new( x + r, y + h - r, 0 )
              points.concat( TT::Geom3d.arc( c, x_axis, z, r, 270.degrees, 360.degrees, 8 ) )
              #
              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_POLYGON )
            else
              points << Geom::Point3d.new( x, y, 0 )
              points << Geom::Point3d.new( x + w, y, 0 )
              points << Geom::Point3d.new( x + w, y + h, 0 )
              points << Geom::Point3d.new( x, y + h, 0 )
              adjust_points!( points, false, offset )
              add_instruction( instructions, :draw2d, points, GL_QUADS )
            end
          when 'POLYGON'
            points = data
            adjust_points!( points, false, offset )
            add_instruction( instructions, :draw2d, points, GL_POLYGON )
          when 'PIE'
            center, radius, degrees, segments, start_angle = data
            start_angle = (start_angle) ? start_angle.degrees : 0.0
            end_angle = start_angle + degrees.degrees
            points = TT::Geom3d.arc( center, X_AXIS.reverse, Z_AXIS, radius, start_angle, end_angle, segments )
            points.unshift( center )
            adjust_points!( points, false, offset )
            add_instruction( instructions, :draw2d, points, GL_TRIANGLE_FAN )
          when 'DISC'
            center, radius, segments = data
            points = TT::Geom3d.circle( center, Z_AXIS, radius, segments )
            adjust_points!( points, false, offset )
            add_instruction( instructions, :draw2d, points, GL_POLYGON )
          when 'GRADIENT'
            x, y, w, h, steps, vertical, color1, color2 = data
            n = ( vertical ) ? w / steps : h / steps
            r = 1.0 / steps
            for i in ( 0...steps )
              points = []
              if vertical
                x1 = x + (n * i)
                y1 = y
                w1 = n
                h1 = h
              else
                x1 = x
                y1 = y + (n * i)
                w1 = w
                h1 = n
              end
              points << Geom::Point3d.new( x1, y1, 0 )
              points << Geom::Point3d.new( x1 + w1, y1, 0 )
              points << Geom::Point3d.new( x1 + w1, y1 + h1, 0 )
              points << Geom::Point3d.new( x1, y1 + h1, 0 )
              adjust_points!( points, false, offset )
              c = color2.blend( color1, r * i )
              add_instruction( instructions, :drawing_color=, [c] )
              add_instruction( instructions, :draw2d, points, GL_QUADS )
            end
          else
            raise( ParseError, "Unknown drawing instruction. (#{command})\n\t#{line.inspect}" )
          end
        }
      }
      instructions
    end

    # On nVidia cards an odd width line must have the co-ordinates in the center
    # of the pixel - otherwise the line will be aliased between the pixels on
    # either side.
    #
    # @param [Array<Geom::Point3d>] points
    # @param [Boolean] odd_width
    # @param [Geom::Vector3d] offset
    #
    # @return [Array]
    # @since 2.7.0
    def adjust_points!( points, odd_width, offset )
      total_offset = offset.clone
      if odd_width
        pixel_grid = Geom::Vector3d.new( 0.5, 0.5, 0.0 )
        total_offset = total_offset + pixel_grid
      end
      tr = Geom::Transformation.new( total_offset )
      for point in points
        point.transform!( tr )
      end
      nil
    end

    # @param [Array] instructions
    # @param [Symbol] command
    # @param [Array] arguments
    # @param [Integer] draw_operation
    #
    # @return [Array]
    # @since 2.7.0
    def add_instruction( instructions, command, arguments, draw_operation = nil )
      last_instruction = instructions.last
      # Prepend any drawing operation.
      if draw_operation
        arguments.unshift( draw_operation )
      end
      # If there where no previous command or the last command was different
      # there is no optimization to be made.
      if last_instruction.nil? || last_instruction[0] != command
        instructions << [ command, arguments ]
        return nil
      end
      # Merge commands
      case command
      when :drawing_color=, :line_width=
        # Remove command that override each other.
        instructions.pop
        instructions << [ command, arguments ]
      when :draw2d
        # Merge operations when possible.
        current_operation = arguments[0]
        case current_operation
        when GL_POINTS, GL_LINES, GL_TRIANGLES, GL_QUADS
          # These operations can safely be merged if they appear in sequence.
          last_operation = last_instruction[1][0]
          if current_operation == last_operation
            arguments.shift
            last_instruction[1].concat( arguments )
          else
            instructions << [ command, arguments ]
          end
        else
          # All other operations cannot be merged.
          instructions << [ command, arguments ]
        end
      end
      instructions
    end

    # @param [String] line
    #
    # @return [Array]
    # @since 2.7.0
    def decode_line( line )
      parts = line.split(/\s/)
      args = []
      for part in parts
        next if part.empty?
        if r = part.match( /^\<(\d+),(\d+),(\d+)(?:,(\d+))?\>$/ )
          # Colour - <255,64,0> - <255,64,0,64>
          color = r.captures.compact.map { |str| str.to_i }
          args << Sketchup::Color.new( color )
        elsif r = part.match( /^\[(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)\]$/ )
          # Point2d - [-20,30] - [20.5,-30.5]
          x, y = r.captures.map! { |str| str.to_f }
          args << Geom::Point3d.new( x, y, 0 )
        elsif part.match( /^(-?\d+(?:\.\d+)?)$/ )
          # Number
          args << part.to_f
        elsif part.match( /^true$/i )
          args << true
        elsif part.match( /^false$/i )
          args << false
        else
          args << part
        end
      end
      args
    end

  end # class TT::GL_Image
end
