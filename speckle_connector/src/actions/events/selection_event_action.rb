# frozen_string_literal: true

require_relative 'event_action'

module SpeckleConnector
  module Actions
    module Events
      # Update selected speckle objects when the selection changes for mapping tool.
      class SelectionEventAction < EventAction
        # @param state [States::State] the current state of Speckle application.
        # @return [States::State] the new updated state object
        def self.update_state(state, event_data)
          return state unless event_data&.any?

          selection = [
            {a: 1},
            {b: 1}
          ]
          selection = [] if state.sketchup_state.sketchup_model.selection.none?

          state.with_selection_queue(selection)
        end
      end
    end
  end
end
