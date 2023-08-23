#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'point3d.rb'

# @since 2.0.0
module SpeckleConnector
  module TT::Geom3d

    # Returns +plane+ in the format +[ point3d, vector3d ]+.
    #
    # @param [Array<Geom::Point3d, Geom::Vector3d>, Array<Number, Number, Number, Number>] plane
    #
    # @return [Array<Geom::Point3d, Geom::Vector3d>]
    # @since 2.0.0
    def self.normalize_plane(plane)
      return plane if plane.length == 2
      a, b, c, d = plane
      v = Geom::Vector3d.new(a,b,c)
      p = ORIGIN.offset(v.reverse, d)
      return [p, v]
    end


    # Check if all points in the array are on the same plane.
    #
    # @todo Ensure that the points are not co-linear. (Edge case)
    #
    # @param [Array<Geom::Point3d|Sketchup::Vertex>] points
    #
    # @since 2.0.0
    def self.planar_points?(points)
      points = TT::Point3d.extend_all( points )
      points.uniq!
      return false if points.size < 3
      plane = Geom.fit_plane_to_points( points )
      points.all? { |pt| pt.on_plane?( plane ) }
    end


    # Creates a set of +Geom::Point3d+ objects for an arc.
    #
    # @param [Geom::Point3d] center
    # @param [Geom::Vector3d] xaxis
    # @param [Geom::Vector3d] normal
    # @param [Number] radius
    # @param [Float] start_angle in radians
    # @param [Float] end_angle in radians
    # @param [Integer] num_segments
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.0.0
    def self.arc(center, xaxis, normal, radius, start_angle, end_angle, num_segments = 12)
      # Generate the first point.
      t = Geom::Transformation.rotation(center, normal, start_angle )
      points = []
      points << center.offset(xaxis, radius).transform(t)
      # Prepare a transformation we can repeat on the last entry in point to complete the arc.
      t = Geom::Transformation.rotation(center, normal, (end_angle - start_angle) / num_segments )
      1.upto(num_segments) { |i|
        points << points.last.transform(t)
      }
      return points
    end


    # @see http://en.wikipedia.org/wiki/Circle
    # @see http://en.wikipedia.org/wiki/Unit_Circle
    #
    # @param [Geom::Point3d] center
    # @param [Geom::Vector3d] xaxis
    # @param [Numeric] radius
    # @param [Numeric] start_angle
    # @param [Numeric] end_angle
    # @param [Integer] segments
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.7.0
    def self.arc2d( center, xaxis, radius, start_angle, end_angle, segments = 24 )
      full_angle = end_angle - start_angle
      segment_angle = full_angle / segments
      t = Geom::Transformation.axes( center, xaxis, xaxis * Z_AXIS, Z_AXIS )
      arc = []
      (0..segments).each { |i|
        angle = start_angle + (segment_angle * i)
        x = radius * Math.cos(angle)
        y = radius * Math.sin(angle)
        arc << Geom::Point3d.new(x,y,0).transform!(t)
      }
      arc
    end


    # Creates a set of +Geom::Point3d+ objects for an circle.
    #
    # @param [Geom::Point3d] center
    # @param [Geom::Vector3d] normal
    # @param [Number] radius
    # @param [Integer] num_segments
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.0.0
    def self.circle(center, normal, radius, num_segments)
      points = self.arc(center, normal.axes.x, normal, radius, 0.0, Math::PI * 2, num_segments)
      points.pop
      return points
    end


    # @param [Geom::Point3d] center
    # @param [Geom::Vector3d] xaxis
    # @param [Numeric] radius
    # @param [Integer] segments
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.7.0
    def self.circle2d( center, xaxis, radius, segments = 24 )
      segments = segments.to_i
      angle = 360.degrees - ( 360.degrees / segments )
      self.arc2d( center, xaxis, radius, 0, angle, segments - 1 )
    end


    # Calculates the number of segments in an arc given the segments of a full circle. This
    # will give a close visual quality of the arcs and circles.
    #
    # @param [Float] angle in radians
    # @param [Integer] full_circle_segments
    # @param [Boolean] force_even useful to ensure the segmented arc's
    #   apex hits the apex of the real arc
    #
    # @return [Integer]
    # @since 2.0.0
    def self.arc_segments(angle, full_circle_segments, force_even = false)
      segments = (full_circle_segments * (angle.abs / (Math::PI * 2))).to_i
      segments += 1 if force_even && segments % 2 > 0 # if odd
      segments = 1 if segments < 1
      return segments
    end


    # Evenly distribute a fixed number of points on a sphere.
    # http://www.cgafaq.info/wiki/Evenly_distributed_points_on_sphere
    #
    # @param [Integer] number_of_points
    # @param [Geom::Point3d] origin
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.3.0
    def self.spiral_sphere( number_of_points, origin=ORIGIN )
      t = Geom::Transformation.new( origin )
      n = number_of_points
      node = Array.new( n )
      dlong = Math::PI * (3-Math.sqrt(5))
      dz = 2.0/n
      long = 0
      z = 1 - dz/2
      (0...n).each { |k|
        r = Math.sqrt( 1-z*z )
        pt = Geom::Point3d.new( Math.cos(long)*r, Math.sin(long)*r, z )
        node[k] = pt.transform( t )
        z = z - dz
        long = long + dlong
      }
      node
    end


    # @param [Geom::Point3d] point1
    # @param [Geom::Point3d] point2
    # @param [Integer] subdivs The number of resulting segments
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.5.0
    def self.interpolate_linear(point1, point2, subdivs)
      step = 1.0 / subdivs
      pts = []
      (0..subdivs).each { |i|
        r = step * i
        pts << Geom::linear_combination( r, point1, 1.0 - r, point2 )
      }
      pts
    end


    # @param [Array<Geom::Point3d>] points
    #
    # @return [Geom::Point3d]
    # @since 2.5.0
    def self.average_point(points)
      average = Geom::Point3d.new(0,0,0)
      return average if points.empty?
      number_of_points = points.length
      for pt in points
        average.x += pt.x
        average.y += pt.y
        average.z += pt.z
      end
      average.x = average.x / number_of_points
      average.y = average.y / number_of_points
      average.z = average.z / number_of_points
      average
    end

  end # module TT::Geom3D
end
