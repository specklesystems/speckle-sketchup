# frozen_string_literal: true

module SpeckleConnector
  module Actions
    # This module contains actions that are performed to handle events triggered by observers in Sketchup.
    module Events
      # Base action for Handling events
      class EventAction
        def self.actions
          raise NoMethodError, 'Implement in a subclass'
        end

        # Handle the events that were collected by the observer. In case of the selection observer,
        # we only need to handle the events once if any of the events actually happened.
        # @param event_data [Hash{Symbol=>Array}] the event data grouped by the event name
        # @param state [States::State] the current state of the Speckle
        # @return [States::State] the transformed state
        def self.update_state(state, events)
          # Don't do anything if there are no events for this action
          return state unless events

          actions = self.actions
          actions.each do |event_name, action|
            next unless events.key?(event_name)

            event_data = events[event_name]
            state = action.update_state(state, event_data)
          end
          state
        end
      end
    end
  end
end
