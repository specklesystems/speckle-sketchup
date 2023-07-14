# frozen_string_literal: true

require_relative 'event_action'
require_relative 'on_document_changed'
require_relative '../load_sketchup_model'
require_relative '../collect_preferences'

module SpeckleConnector
  module Actions
    module Events
      # Handle events that are triggered by the {AppObserver}.
      class AppEventAction < EventAction
        # Handle loading new or existing model
        class OnNewOrChangedModel
          # Handle events when the new or existing model is loaded in Sketchup
          # @param state [States::State] the current state of speckle application
          # @param event_data [Array<(Sketchup::Model)>] the event data for the given event. It consists of
          #  a double array with a single element that is the {Sketchup::Model} object of the loaded model.
          def self.update_state(state, event_data)
            return state unless event_data&.any?

            model = event_data.flatten.first
            # LoadSketchupModel action should be responsible to update all model specific data for state and then
            #  should notify the UI to update it's components.
            new_state = Actions::LoadSketchupModel.update_state(state, model)
            # Action to let UI to render itself with new preferences state
            # TODO: Later UI should be updated if any stream is invalid after
            #  we collected speckle_entities appropriately
            # new_state = CollectPreferences.update_state(new_state, nil, {})
            OnDocumentChanged.update_state(new_state)
          end
        end

        # Run actions that are needed before the sketchup quits
        class OnQuit
          # Handle when Sketchup application closes
          # @param state [States::State] the current state of speckle application
          # @param _event_data [Array] the event data
          # @return [States::State] the transformed state object
          def self.update_state(state, _event_data)
            state
          end
        end

        # Handlers that are used to handle specific events
        ACTIONS = {
          onNewModel: OnNewOrChangedModel,
          onOpenModel: OnNewOrChangedModel,
          onQuit: OnQuit
        }.freeze

        def self.actions
          ACTIONS
        end
      end
    end
  end
end
