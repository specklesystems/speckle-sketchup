# frozen_string_literal: true

require_relative 'event_hash'
require_relative '../actions/on_events_action'

module SpeckleConnector
  module Observers
    class EventHandler
      # @return [SpeckleConnectorApp] an object that contains current state of speckle objects
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def handle_events(events)
        run_handlers(events)
      end

      def run_handlers(events)
        app.update_state!(Actions::OnEventsAction, events)
      end
    end
  end
end
