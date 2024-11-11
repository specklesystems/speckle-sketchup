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
          normal = Vector.to_native(plane['normal']['x'], plane['normal']['y'], plane['normal']['z'], units)
          x_axis = Vector.to_native(plane['xdir']['x'], plane['xdir']['y'], plane['xdir']['z'], units)
          radius = Geometry.length_to_native(arc['radius'], units)

          start_vector = Vector.to_native(start_point.x - origin.x, start_point.y - origin.y, start_point.z - origin.z, units)
          end_vector = Vector.to_native(end_point.x - origin.x, end_point.y - origin.y, end_point.z - origin.z, units)

          start_angle = Math.atan2(start_vector.cross(normal).dot(x_axis), start_vector.dot(x_axis))
          end_angle = Math.atan2(end_vector.cross(normal).dot(x_axis), end_vector.dot(x_axis))

          if end_angle < start_angle
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
