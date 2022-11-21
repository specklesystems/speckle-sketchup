# frozen_string_literal: true

require_relative '../speckle_geometry_object'

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      # Vector object definition for Speckle.
      class Vector < SpeckleGeometryObject
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          x: Numeric,
          y: Numeric,
          z: Numeric
        }.freeze

        def initialize(x, y, z, units)
          super(
            'Objects.Geometry.Vector',
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
