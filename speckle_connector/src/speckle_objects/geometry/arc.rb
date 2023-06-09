# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector
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
          edges = entities.add_arc(origin, x_axis, normal, radius, arc['startAngle'], arc['endAngle'])
          edges.each { |edge| edge.layer = layer }
          return state, edges
        end
      end
    end
  end
end
