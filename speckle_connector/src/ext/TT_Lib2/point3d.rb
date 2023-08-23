#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'point3d_ex.rb'

module SpeckleConnector
  # Collection of Point3d methods.
  #
  # @since 2.0.0
  module TT::Point3d

    # Checks if point +c+ is between point +a+ and +b+.
    #
    # Return true if +c+ is on +a+ or +b+.
    #
    # @param [Geom::Point3d] a
    # @param [Geom::Point3d] b
    # @param [Geom::Point3d] c
    # @param [Geom::Point3d] on_point - When +true+, if point +c+ is at the same
    #   position as +a+ or +b+ it is considered to be in between.
    #
    # @return [Boolean]
    # @since 2.0.0
    def self.between?(a, b, c, on_point = true)
      return false unless c.on_line?([a,b])
      v1 = c.vector_to(a)
      v2 = c.vector_to(b)
      if on_point
        return true  if !v1.valid? || !v2.valid?
      else
        return false if !v1.valid? || !v2.valid?
      end
      !v1.samedirection?(v2)
    end


    # Implementation of the Douglas-Peucker algorithm.
    #
    # http://en.wikipedia.org/wiki/Ramer-Douglas-Peucker_algorithm
    # http://en.wiki.mcneel.com/default.aspx/McNeel/PolylineSimplification.html
    #
    # @param [Array<Geom::Point3d>] points Point set to be simplified. No Loop!
    # @param [Length] epsilon Maximin deviance from original curve.
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.5.0
    def self.douglas_peucker(points, epsilon)
      return points if points.length < 3
      # Find the point with the maximum distance
      dmax = 0
      index = 0
      line = [points.first, points.last]
      1.upto(points.length - 2) { |i|
        d = points[i].distance_to_line(line)
        if d > dmax
          index = i
          dmax = d
        end
      }
      # If max distance is greater than epsilon, recursively simplify
      result = []
      if dmax >= epsilon
        # Recursive call
        recResults1 = self.douglas_peucker(points[0..index], epsilon)
        recResults2 = self.douglas_peucker(points[index...points.length], epsilon)
        # Build the result list
        result = recResults1[0...-1] + recResults2
      else
        result = [points.first, points.last]
      end
      return result
    end


    # Extends all the points (+Geom::Point3d+ and +Array+ in +points+) with the
    # +TT::Point3d_Ex+ mix-in module.
    #
    # All +Array+ objects that represent a 3d point will be converted into
    # +Geom::Point3d+ before being extended.
    #
    # @param [Array<Geom::Point3d>] points
    #
    # @return [Array<TT::Point3d_Ex>] Geom::Point3d objects extended by TT::Point3d_Ex
    # @since 2.5.0
    def self.extend_all( points )
      extended_points = []
      for point in points
        if point.is_a?( Geom::Point3d )
          point_ex = point
        elsif point.is_a?( Array )
          next unless point.size == 3 && point.all? { |n| n.is_a?( Numeric ) }
          point_ex = Geom::Point3d.new( point.x, point.y, point.z )
        elsif point.respond_to?( :position )
          position = point.position
          point_ex = position if position.is_a?( Geom::Point3d )
        end
        point_ex.extend( TT::Point3d_Ex ) unless point_ex.is_a?( TT::Point3d_Ex )
        extended_points << point_ex
      end
      extended_points
    end


    # Wrapper of the Douglas-Peucker algorithm. Handles looping curves.
    #
    # @param [Array<Geom::Point3d>] points Point set to be simplified. No Loop!
    # @param [Length] epsilon Maximin deviance from original curve.
    #
    # @return [Array<Geom::Point3d>]
    # @since 2.5.0
    def self.simplify_curve(points, epsilon)
      if points.first == points.last # Detect loop
        points.pop
        simplified_curve = self.douglas_peucker(points, epsilon)
        simplified_curve << points.first
      else
        simplified_curve = self.douglas_peucker(points, epsilon)
      end
    end

  end # module TT::Point3d
end
