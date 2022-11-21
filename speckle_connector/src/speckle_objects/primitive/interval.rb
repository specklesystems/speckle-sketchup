# frozen_string_literal: true

require_relative '../speckle_geometry_object'

module SpeckleConnector
  module SpeckleObjects
    module Primitive
      # Interval object definition for Speckle.
      class Interval < SpeckleGeometryObject
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          start: Numeric,
          end: Numeric
        }.freeze

        def initialize(start_value, end_value, units)
          super(
            'Objects.Primitive.Interval',
            units,
            {
              start: start_value,
              end: end_value
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
