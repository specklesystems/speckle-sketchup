# frozen_string_literal: true

module SpeckleConnector
  module Converters
    # Helper class to convert geometries between server and Sketchup.
    class ConverterV2
      # @return [States::State] the current state of the {SpeckleConnector::App}
      attr_reader :state

      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_reader :speckle_state

      # @return [Sketchup::Model] active sketchup model.
      attr_reader :sketchup_model

      # @return [String] stream id that conversion happening with it
      attr_reader :stream_id

      # @return [String] speckle units
      attr_reader :units

      attr_reader :model_card_id

      attr_reader :model_prefix

      attr_accessor :definitions

      # @param state [States::State] the current state of the {SpeckleConnector::App}
      # @param model_card [Cards::Card] model card that holds info for operation
      def initialize(state, model_card)
        @state = state
        @model_prefix = "Project: #{model_card.project_name}, Model: #{model_card.model_name}"
        @model_card_id = model_card.model_card_id
        @speckle_state = state.speckle_state
        @sketchup_model = state.sketchup_state.sketchup_model
        @project_id = model_card.project_id
        su_unit = state.sketchup_state.length_units
        @units = Converters::SKETCHUP_UNITS[su_unit]
        @definitions = {}
      end
    end
  end
end
