# frozen_string_literal: true

module SpeckleConnector
  module Converters
    # Helper class to convert geometries between server and Sketchup.
    class Converter
      # @return [Sketchup::Model] active sketchup model.
      attr_reader :sketchup_model

      # @return [String] speckle units
      attr_reader :units

      attr_accessor :definitions

      # @param sketchup_state [States::SketchupState] the current sketchup state of the {States::State}
      def initialize(sketchup_state)
        @sketchup_model = sketchup_state.sketchup_model
        su_unit = sketchup_state.length_units
        @units =  Converters::SKETCHUP_UNITS[su_unit]
        @definitions = {}
      end
    end
  end
end
