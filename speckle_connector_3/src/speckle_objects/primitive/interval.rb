# frozen_string_literal: true

require_relative '../base'
require_relative '../../speckle_objects/geometry/length'

module SpeckleConnector3
  module SpeckleObjects
    module Primitive
      # Interval object definition for Speckle.
      class Interval < Base
        SPECKLE_TYPE = 'Objects.Primitive.Interval'

        # @param units [String] units of the interval.
        # @param start_value [Numeric] start value of the transform.
        # @param end_value [Numeric] end value of the transform.
        def initialize(units:, start_value:, end_value:)
          super(
            speckle_type: SPECKLE_TYPE,
            application_id: nil,
            id: nil
          )
          self[:units] = units
          self[:start] = start_value
          self[:end] = end_value
        end

        def self.from_numeric(start_value, end_value, units)
          Interval.new(
            units: units,
            start_value: start_value,
            end_value: end_value
          )
        end

        def self.from_lengths(length_1, length_2, units)
          start_value = Geometry.length_to_speckle(length_1, units)
          end_value = Geometry.length_to_speckle(length_2, units)
          from_numeric(start_value, end_value, units)
        end
      end
    end
  end
end
