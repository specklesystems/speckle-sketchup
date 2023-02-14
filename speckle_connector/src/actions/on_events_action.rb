# frozen_string_literal: true

require_relative 'action'
require_relative 'events/app_event_action'
require_relative 'events/entities_event_action'
require_relative 'events/model_event_action'
require_relative '../constants/observer_constants'

module SpeckleConnector
  module Actions
    # Handle events that were collected by observers
    class OnEventsAction < Action
      RUN_ORDER = {
        APP_OBSERVER => Events::AppEventAction,
        ENTITIES_OBSERVER => Events::EntitiesEventAction,
        MODEL_OBSERVER => Events::ModelEventAction,
        # MATERIALS_OBSERVER => Events::MaterialsEventAction,
        # LAYERS_OBSERVER => Events::LayerEventAction,
        # PAGES_OBSERVER => Events::PagesEventAction,
        # SELECTION_OBSERVER => Events::SelectionEventAction
      }.freeze

      def self.update_state(state, events)
        RUN_ORDER.each do |observer_name, action|
          next unless events.key?(observer_name)

          parameters = events[observer_name]
          state = action.update_state(state, parameters)
        end
        state
      end
    end
  end
end
