# frozen_string_literal: true

module SpeckleConnector3
  module Converters
    # Helper class to convert geometries between server and Sketchup.
    class Converter
      # @return [States::State] the current state of the {SpeckleConnector3::App}
      attr_reader :state

      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_reader :speckle_state

      # @return [Sketchup::Model] active sketchup model.
      attr_reader :sketchup_model

      # @return [String] stream id that conversion happening with it
      attr_reader :stream_id

      # @return [String] speckle units
      attr_reader :units

      attr_accessor :definitions

      # @param state [States::State] the current state of the {SpeckleConnector3::App}
      def initialize(state, stream_id)
        @state = state
        @speckle_state = state.speckle_state
        @sketchup_model = state.sketchup_state.sketchup_model
        @stream_id = stream_id
        su_unit = state.sketchup_state.length_units
        @units = Converters::SKETCHUP_UNITS[su_unit]
        @definitions = {}
      end
    end
  end
end
