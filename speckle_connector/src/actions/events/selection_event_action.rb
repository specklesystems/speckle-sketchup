# frozen_string_literal: true

require_relative 'event_action'
require_relative '../mapper_selection_changed'
require_relative '../selection_actions/get_selection'
require_relative '../../mapper/category/revit_category'
require_relative '../../sketchup_model/reader/speckle_entities_reader'
require_relative '../../sketchup_model/reader/mapper_reader'
require_relative '../../sketchup_model/query/entity'

module SpeckleConnector
  module Actions
    module Events
      # Update selected speckle objects when the selection changes for mapper tool.
      class SelectionEventAction < EventAction
        # @param state [States::State] the current state of Speckle application.
        # @return [States::State] the new updated state object
        def self.update_state(state, event_data)
          return state unless event_data&.any?

          # Get sketchup selection
          sketchup_selection = state.sketchup_state.sketchup_model.selection

          Actions::GetSelection.update_state(state)

          # Collect and return mapper selection info.
          # Later we can add more selection info for different scopes.
          # MapperSelectionChanged.new(sketchup_selection).update_state(state)
        end
      end
    end
  end
end
