# frozen_string_literal: true

module SpeckleConnector
  module SpeckleObjects
    # Geometric objects to convert speckle.
    module Geometry
      def self.length_to_speckle(length, units)
        length.__send__("to_#{SpeckleConnector::Converters::SKETCHUP_UNIT_STRINGS[units]}")
      end

      def self.length_to_native(length, units)
        length.__send__(SpeckleConnector::Converters::SKETCHUP_UNIT_STRINGS[units])
      end
    end
  end
end
