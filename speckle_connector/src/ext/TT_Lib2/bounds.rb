#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Collection of BoundingBox methods.
#
# @since 2.2.0
module SpeckleConnector
  module TT::Bounds

    # Returns a +Point3d+ from a standard position of the boundingbox.
    #
    # @param [Geom::BoundingBox] bounds
    # @param [Integer] index
    #
    # @return [Geom::Point3d]
    # @since 2.2.0
    def self.point(bounds, index)
      case index
      when 0..7
        pt = bounds.corner(index)

      when TT::BB_CENTER_FRONT_BOTTOM
        p1 = bounds.corner( TT::BB_LEFT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_FRONT_BOTTOM )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_BACK_BOTTOM
        p1 = bounds.corner( TT::BB_LEFT_BACK_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_BOTTOM )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_FRONT_TOP
        p1 = bounds.corner( TT::BB_LEFT_FRONT_TOP )
        p2 = bounds.corner( TT::BB_RIGHT_FRONT_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_BACK_TOP
        p1 = bounds.corner( TT::BB_LEFT_BACK_TOP )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )

      when TT::BB_LEFT_CENTER_BOTTOM
        p1 = bounds.corner( TT::BB_LEFT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_LEFT_BACK_BOTTOM )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_LEFT_CENTER_TOP
        p1 = bounds.corner( TT::BB_LEFT_FRONT_TOP )
        p2 = bounds.corner( TT::BB_LEFT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_RIGHT_CENTER_BOTTOM
        p1 = bounds.corner( TT::BB_RIGHT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_BOTTOM )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_RIGHT_CENTER_TOP
        p1 = bounds.corner( TT::BB_RIGHT_FRONT_TOP )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )

      when TT::BB_LEFT_FRONT_CENTER
        p1 = bounds.corner( TT::BB_LEFT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_LEFT_FRONT_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_RIGHT_FRONT_CENTER
        p1 = bounds.corner( TT::BB_RIGHT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_FRONT_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_LEFT_BACK_CENTER
        p1 = bounds.corner( TT::BB_LEFT_BACK_BOTTOM )
        p2 = bounds.corner( TT::BB_LEFT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_RIGHT_BACK_CENTER
        p1 = bounds.corner( TT::BB_RIGHT_BACK_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )

      when TT::BB_LEFT_CENTER_CENTER
        p1 = bounds.corner( TT::BB_LEFT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_LEFT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_RIGHT_CENTER_CENTER
        p1 = bounds.corner( TT::BB_RIGHT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_FRONT_CENTER
        p1 = bounds.corner( TT::BB_LEFT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_FRONT_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_BACK_CENTER
        p1 = bounds.corner( TT::BB_LEFT_BACK_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_CENTER_TOP
        p1 = bounds.corner( TT::BB_LEFT_FRONT_TOP )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_TOP )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )
      when TT::BB_CENTER_CENTER_BOTTOM
        p1 = bounds.corner( TT::BB_LEFT_FRONT_BOTTOM )
        p2 = bounds.corner( TT::BB_RIGHT_BACK_BOTTOM )
        pt = Geom.linear_combination( 0.5, p1, 0.5, p2 )

      when TT::BB_CENTER_CENTER_CENTER
        pt = bounds.center
      end

      pt
    end

  end # module TT::Bounds
end
