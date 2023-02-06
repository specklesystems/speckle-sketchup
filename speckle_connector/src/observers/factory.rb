# frozen_string_literal: true

require_relative 'app_observer'
require_relative 'entities_observer'
require_relative 'observer_handler'
require_relative 'event_handler'
require_relative '../constants/observer_constants'

module SpeckleConnector
  module Observers
    # Factory class to create observers and it's handler
    module Factory
      module_function

      def create_handler(app)
        event_handler = EventHandler.new(app)
        ObserverHandler.new(event_handler)
      end

      def create_observers(handler)
        {
          APP_OBSERVER => AppObserver.new(handler),
          ENTITIES_OBSERVER => EntitiesObserver.new(handler)
        }.freeze
      end
    end
  end
end
