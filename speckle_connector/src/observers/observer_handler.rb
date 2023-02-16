# frozen_string_literal: true

require_relative 'event_hash'

module SpeckleConnector
  module Observers
    # Class to handle observer events.
    class ObserverHandler
      # @return [EventHash] registered events
      attr_reader :events

      # @return [Float] time when first observer was added
      attr_reader :start_time

      def initialize(event_handler)
        @event_handler = event_handler
        clear_events!
        @observers_disabled = false
        @observers_in_progress = false
        @timer_in_progress = false
      end

      def handle_event!(observer_class, event_name, data)
        puts "## Register #{observer_class} event #{event_name} ##"
        puts "  data = #{data.inspect}"
        return if observers_disabled?

        @events = @events.push_event(observer_class, event_name, data)
        finish
      end

      def finish
        return if @observers_in_progress

        @observers_in_progress = true
        @start_time = Time.now.to_f
        UI.start_timer(0, false) { finish_in_timer }
      end

      def finish_in_timer
        return if @timer_in_progress

        @timer_in_progress = true
        @event_handler.handle_events(events)
      ensure
        clear_events!
        @observers_in_progress = false
        @timer_in_progress = false
      end

      def observers_disabled?
        @observers_disabled
      end

      def with_observers_disabled(&block)
        previous_state = @observers_disabled
        @observers_disabled = true
        block.call
      ensure
        @observers_disabled = previous_state
      end

      def clear_events!
        @events = EMPTY_EVENT_HASH
      end
    end
  end
end
