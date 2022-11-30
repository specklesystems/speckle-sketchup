# frozen_string_literal: true

require_relative '../../typescript/typescript_object'
require_relative '../../speckle_objects/geometry/length'

module SpeckleConnector
  module SpeckleObjects
    module Primitive
      # Interval object definition for Speckle.
      class Interval < Typescript::TypescriptObject
        SPECKLE_TYPE = 'Objects.Primitive.Interval'
        ATTRIBUTES = {
          speckle_type: String,
          units: String,
          start: Numeric,
          end: Numeric
        }.freeze

        def self.from_numeric(start_value, end_value, units)
          Interval.new(
            speckle_type: SPECKLE_TYPE,
            units: units,
            start: start_value,
            end: end_value
          )
        end

        def self.from_lengths(length_1, length_2, units)
          start_value = Geometry.length_to_speckle(length_1, units)
          end_value = Geometry.length_to_speckle(length_2, units)
          from_numeric(start_value, end_value, units)
        end

        def attribute_types
          ATTRIBUTES
        end
      end
    end
  end
end
