# frozen_string_literal: true

require_relative '../../convertors/units'

module SpeckleConnector3
  module SpeckleObjects
    # Geometric objects to convert speckle.
    module Geometry
      def self.length_to_speckle(length, units)
        length.__send__("to_#{SpeckleConnector3::Converters::SKETCHUP_UNIT_STRINGS[units]}")
      end

      def self.length_to_native(length, units)
        if units == 'none'
          units = SpeckleConnector3::Converters::
              SKETCHUP_UNITS[Sketchup.active_model.options['UnitsOptions']['LengthUnit']]
        end
        length.__send__(SpeckleConnector3::Converters::SKETCHUP_UNIT_STRINGS[units])
      end
    end
  end
end
