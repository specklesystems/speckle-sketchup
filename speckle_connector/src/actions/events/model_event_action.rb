# frozen_string_literal: true

require_relative 'event_action'
require_relative '../load_sketchup_model'

module SpeckleConnector
  module Actions
    module Events
      # Handle events that are triggered by the {ModelObserver}.
      class ModelEventAction < EventAction
        # Handle loading new or existing model
        class OnActivePathChanged
          # Handle events when the new or existing model is loaded in Sketchup
          # @param state [States::State] the current state of speckle application
          # @param event_data [Array<(Sketchup::Model)>] the event data for the given event. It consists of
          #  a double array with a single element that is the {Sketchup::Model} object of the loaded model.
          def self.update_state(state, _event_data)
            sketchup_state = state.sketchup_state
            active_path = sketchup_state.sketchup_model.active_path
            observers = state.speckle_state.observers
            update_object_observers(active_path, observers)
            return state
          end

          def self.update_object_observers(path, observers)
            path[-1].definition.entities.add_observer(observers[ENTITIES_OBSERVER]) unless path.nil?
          end
        end

        # Handlers that are used to handle specific events
        ACTIONS = {
          onActivePathChanged: OnActivePathChanged
        }.freeze

        def self.actions
          ACTIONS
        end
      end
    end
  end
end
