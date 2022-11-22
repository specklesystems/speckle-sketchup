# frozen_string_literal: true

require_relative 'length'
require_relative '../../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Point object definition for Speckle.
      class Point < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Geometry.Point'
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          x: Numeric,
          y: Numeric,
          z: Numeric
        }.freeze

        def self.from_coordinates(x, y, z, units)
          Point.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            x: x,
            y: y,
            z: z
          )
        end

        def self.from_vertex(vertex, units)
          Point.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            x: Geometry.length_to_speckle(vertex[0], units),
            y: Geometry.length_to_speckle(vertex[1], units),
            z: Geometry.length_to_speckle(vertex[2], units)
          )
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
