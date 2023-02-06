# frozen_string_literal: true

require_relative 'event_hash'
require_relative '../actions/on_events_action'

module SpeckleConnector
  module Observers
    # Observer classes includes it to check common operations for all observer classes.
    module Observable
      # @return [ObserverHandler] handler for observer events
      attr_reader :observer_handler

      def initialize(observer_handler)
        super()
        @observer_handler = observer_handler
      end

      def push_event(event_name, *event_data)
        return if observers_disabled?

        @observer_handler.handle_event!(self.class.name, event_name, event_data)
      end

      def observers_disabled?
        @observer_handler.observers_disabled?
      end

      # Push event only once. If the event is already registered, don't push it again
      # @param event_name [Symbol] the name of the event
      # @param event_data [Array] the optional data that comes with the event
      def push_once(event_name, *event_data)
        return if observers_disabled?

        # Don't push anything if the selection event was already registered
        class_events = @observer_handler.events[self.class]
        events = class_events && class_events[event_name]
        return if events&.any?

        push_event(event_name, *event_data)
      end
    end
  end
end
