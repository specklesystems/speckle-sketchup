#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'point3d.rb'

module SpeckleConnector
  # Mix-in module for +Geom::Point3d+.
  #
  # @since 2.5.0
  module TT::Point3d_Ex

    # Checks if a point is on line between two other points.
    #
    # +point1+ and +point2+ should be a +Geom::Point3d+, +Array+ object, or
    # and object that implements a +.position+ method that returns a 3d position.
    #
    # When +on_point+ is +true+ the method will return +true+ if +self+ is equal
    # to +point1+ or +point2+.
    #
    # @param [Geom::Point3d|Mixed] point1
    # @param [Geom::Point3d|Mixed] point2
    # @param [Boolean] on_point
    #
    # @return [Boolean]
    # @since 2.5.0
    def between?( point1, point2, on_point = true )
      point1 = point1.position if point1.respond_to?( :position )
      point2 = point2.position if point2.respond_to?( :position )
      TT::Point3d.between?( point1, point2, self, on_point = true )
    end


    # @param [Object] object
    #
    # @return [Boolean]
    # @since 2.5.0
    def eql?( object )
      self == object
    end


    # @return [Integer]
    # @since 2.5.0
    def hash
      # (!) May return  different hash for identical positions.
      #[self.x.to_f, self.y.to_f, self.z.to_f].hash
      #[self.x, self.y, self.z].hash
      # (!) Experimental!
      # Convert X, Y and Z to ints at 1000th accuracy to avoid inconsistent hash
      # values for identical positions.
      x = ( self.x * 1000 ).to_i
      y = ( self.y * 1000 ).to_i
      z = ( self.z * 1000 ).to_i
      [x, y, z].hash
    end

  end # module TT::Point3d_Ex
end
