# frozen_string_literal: true

module SpeckleConnector3
  module Converters
    # Helper class to convert geometries between server and Sketchup.
    class ConverterV2
      # @return [States::State] the current state of the {SpeckleConnector3::App}
      attr_reader :state

      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_reader :speckle_state

      # @return [Sketchup::Model] active sketchup model.
      attr_reader :sketchup_model

      # @return [Cards::Card] card that conversion happening with it
      attr_reader :model_card

      # @return [String] speckle units
      attr_reader :units

      # @return [String] prefix that structured from Project and Model name
      attr_reader :model_prefix

      attr_accessor :definitions

      # @param state [States::State] the current state of the {SpeckleConnector3::App}
      # @param model_card [Cards::Card] model card that holds info for operation
      def initialize(state, model_card)
        @state = state
        @model_card = model_card
        @model_prefix = "Project: #{model_card.project_name} Model: #{model_card.model_name}"
        @speckle_state = state.speckle_state
        @sketchup_model = state.sketchup_state.sketchup_model
        su_unit = state.sketchup_state.length_units
        @units = Converters::SKETCHUP_UNITS[su_unit]
        @definitions = {}
      end
    end
  end
end
