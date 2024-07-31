# frozen_string_literal: true

require_relative 'point'
require_relative 'vector'
require_relative 'length'
require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    module Geometry
      # Circle object definition for Speckle.
      class Circle < Base
        SPECKLE_TYPE = OBJECTS_GEOMETRY_CIRCLE

        # @param [States::State] state of the current application.
        # @param circle [Object] object represents Speckle Circle.
        # @param layer [Sketchup::Layer] layer to add {Sketchup::Edge} into it.
        # @param entities [Sketchup::Entities] entities collection to add {Sketchup::Edge} into it.
        def self.to_native(state, circle, layer, entities, &_convert_to_native)
          plane = circle['plane']
          units = circle['units']
          origin = Point.to_native(plane['origin']['x'], plane['origin']['y'], plane['origin']['z'], units)
          normal = Vector.to_native(plane['normal']['x'], plane['normal']['y'], plane['normal']['z'], units)
          radius = Geometry.length_to_native(circle['radius'], units)
          edges = entities.add_circle(origin, normal, radius)
          edges.each { |edge| edge.layer = layer }
          return state, edges
        end
      end
    end
  end
end
