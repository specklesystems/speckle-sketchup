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
          start_point = Point.to_native(arc['startPoint']['x'], arc['startPoint']['y'], arc['startPoint']['z'], units)
          end_point = Point.to_native(arc['endPoint']['x'], arc['endPoint']['y'], arc['endPoint']['z'], units)
          normal = Vector.to_native(plane['normal']['x'], plane['normal']['y'], plane['normal']['z'], units).normalize
          x_axis = Vector.to_native(plane['xdir']['x'], plane['xdir']['y'], plane['xdir']['z'], units).normalize
          radius = Geometry.length_to_native(arc['radius'], units)

          start_vector = (start_point - origin).normalize
          end_vector = (end_point - origin).normalize

          x_axis = start_vector.normalize if x_axis.dot(normal).abs > 0.001

          start_angle = Math.atan2(start_vector.cross(normal).dot(x_axis), start_vector.dot(x_axis))
          end_angle = Math.atan2(end_vector.cross(normal).dot(x_axis), end_vector.dot(x_axis))
          # measure = arc['measure'] # Assuming this is in radians
          # end_angle = start_angle + measure

          end_angle += 2 * Math::PI if end_angle < start_angle

          edges = entities.add_arc(origin, x_axis, normal, radius, start_angle, end_angle)
          edges.each { |edge| edge.layer = layer }
          return state, edges
        end
      end
    end
  end
end
