# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    module Geometry
      # Arc object definition for Speckle.
      class Arc < Base
        SPECKLE_TYPE = OBJECTS_GEOMETRY_ARC

        # @param [States::State] state of the current application.
        # @param arc [Object] object represents Speckle Arc.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        def self.to_native(state, arc, layer, entities, &_convert_to_native)
          plane = arc['plane']
          units = arc['units']
          origin = Point.to_native(plane['origin']['x'], plane['origin']['y'], plane['origin']['z'], units)
          normal = Vector.to_native(plane['normal']['x'], plane['normal']['y'], plane['normal']['z'], units)
          x_axis = Vector.to_native(plane['xdir']['x'], plane['xdir']['y'], plane['xdir']['z'], units)
          radius = Geometry.length_to_native(arc['radius'], units)
          start_angle = arc['startAngle']
          end_angle = arc['endAngle']

          # Normalize angles to range 0 to 2π
          start_angle %= 2 * Math::PI
          end_angle %= 2 * Math::PI

          # Ensure start angle is less than end angle for proper drawing
          if start_angle > end_angle
            end_angle += 2 * Math::PI
          end

          edges = entities.add_arc(origin, x_axis, normal, radius, start_angle, end_angle)
          edges.each { |edge| edge.layer = layer }
          return state, edges
        end
      end
    end
  end
end
