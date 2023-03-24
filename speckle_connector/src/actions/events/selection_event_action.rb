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

          state.with_selection_queue(selection)
          # Handle here message to UI according to selection!
          state
        end
      end
    end
  end
end
