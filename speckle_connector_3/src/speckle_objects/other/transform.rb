# frozen_string_literal: true

require_relative '../base'

module SpeckleConnector3
  module SpeckleObjects
    module Other
      # Transform object definition for Speckle.
      class Transform < Base
        SPECKLE_TYPE = 'Objects.Other.Transform'

        attr_reader :value

        # @param units [String] units of the transform.
        # @param value [Array<Numeric>] values of the transform.
        def initialize(units:, value:)
          super(
            speckle_type: SPECKLE_TYPE,
            application_id: nil,
            id: nil
          )
          self[:units] = units
          self[:value] = value
          @value = value
        end

        def self.from_transformation(transformation, units)
          t_arr = transformation.to_a
          Transform.new(
            units: units,
            value: [
              t_arr[0], t_arr[4], t_arr[8], Geometry.length_to_speckle(t_arr[12], units),
              t_arr[1], t_arr[5], t_arr[9], Geometry.length_to_speckle(t_arr[13], units),
              t_arr[2], t_arr[6], t_arr[10], Geometry.length_to_speckle(t_arr[14], units),
              t_arr[3], t_arr[7], t_arr[11], t_arr[15]
            ]
          )
        end

        def self.to_native(t_arr, units)
          Geom::Transformation.new(
            [
              t_arr[0], t_arr[4], t_arr[8], t_arr[12],
              t_arr[1], t_arr[5], t_arr[9], t_arr[13],
              t_arr[2], t_arr[6], t_arr[10], t_arr[14],
              Geometry.length_to_native(t_arr[3], units),
              Geometry.length_to_native(t_arr[7], units),
              Geometry.length_to_native(t_arr[11], units),
              t_arr[15]
            ]
          )
        end
      end
    end
  end
end
