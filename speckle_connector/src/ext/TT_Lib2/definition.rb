#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Collection of Face methods.
#
# @since 2.0.0
module SpeckleConnector
  module TT::Definition

    # Sets the origin of the +ComponentDefinition+ to a given 3d point.
    #
    # @param [Sketchup::ComponentDefinition] definition
    # @param [Geom::Point3d] origin
    #
    # @return [Boolean]
    # @since 2.0.0
    def self.set_origin(definition, origin)
      return false if definition.image?
      # Set the origin - move the entities and counter-adjust the instances.
      t = Geom::Transformation.new( origin )
      definition.entities.transform_entities( t.inverse, definition.entities.to_a )
      definition.instances.each { |i|
        i.transformation = i.transformation * t
      }
      return true
    end


    # Sets the origin of the +ComponentDefinition+ to a given point on its bounds.
    #
    # +origin+ can be an integer of the following values:
    #
    #   BB_LEFT_FRONT_BOTTOM  = 0
    #   BB_RIGHT_FRONT_BOTTOM = 1
    #   BB_LEFT_BACK_BOTTOM   = 2
    #   BB_RIGHT_BACK_BOTTOM  = 3
    #   BB_LEFT_FRONT_TOP     = 4
    #   BB_RIGHT_FRONT_TOP    = 5
    #   BB_LEFT_BACK_TOP      = 6
    #   BB_RIGHT_BACK_TOP     = 7
    #   BB_BOTTOM_CENTER      = 8
    #   BB_TOP_CENTER         = 9
    #   BB_LEFT_CENTER        = 10
    #   BB_RIGHT_CENTER       = 11
    #   BB_FRONT_CENTER       = 12
    #   BB_BACK_CENTER        = 13
    #   BB_CENTER             = 14
    #
    # All these constants are defined under +TT+.
    #
    # @param [Sketchup::ComponentDefinition] definition
    # @param [Integer] origin
    #
    # @return [Boolean]
    # @since 2.0.0
    def self.set_origin_by_bounds(definition, origin)
      return false if definition.image?

      bb = definition.bounds

      # Compute the origin
      if origin.is_a?(Numeric)
        case origin
        when (0..7)
          new_origin = bb.corner(origin)
        when BB_CENTER
          new_origin = bb.center
        when BB_BOTTOM_CENTER
          p1 = bb.corner(BB_LEFT_FRONT_BOTTOM)
          p2 = bb.corner(BB_RIGHT_BACK_BOTTOM)
          new_origin = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        when BB_TOP_CENTER
          p1 = bb.corner(BB_LEFT_FRONT_TOP)
          p2 = bb.corner(BB_RIGHT_BACK_TOP)
          new_origin = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        when BB_LEFT_CENTER
          p1 = bb.corner(BB_LEFT_FRONT_BOTTOM)
          p2 = bb.corner(BB_LEFT_BACK_TOP)
          new_origin = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        when BB_RIGHT_CENTER
          p1 = bb.corner(BB_RIGHT_FRONT_BOTTOM)
          p2 = bb.corner(BB_RIGHT_BACK_TOP)
          new_origin = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        when BB_FRONT_CENTER
          p1 = bb.corner(BB_LEFT_FRONT_BOTTOM)
          p2 = bb.corner(BB_RIGHT_FRONT_TOP)
          new_origin = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        when BB_BACK_CENTER
          p1 = bb.corner(BB_LEFT_BACK_BOTTOM)
          p2 = bb.corner(BB_RIGHT_BACK_TOP)
          new_origin = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
        else
          raise ArgumentError
        end
      elsif origin.is_a?(Geom::Point3d) || (origin.is_a?(Array) && origin.size = 3)
        new_origin = origin
      else
        raise ArgumentError
      end

      self.set_origin(definition, bb.center)
    end

  end # module TT::Definition
end
