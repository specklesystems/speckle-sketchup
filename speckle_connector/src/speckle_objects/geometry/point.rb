# frozen_string_literal: true

require_relative '../speckle_geometry_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Point object definition for Speckle.
      class Point < SpeckleGeometryObject
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          x: Numeric,
          y: Numeric,
          z: Numeric
        }.freeze

        def initialize(x, y, z, units)
          super(
            'Objects.Geometry.Point',
            units,
            **{
              x: x,
              y: y,
              z: z
            }
            )
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
