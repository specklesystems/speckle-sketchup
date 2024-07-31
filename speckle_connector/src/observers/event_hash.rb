# frozen_string_literal: true

require_relative '../ext/immutable_ruby/core'

module SpeckleConnector3
  module Observers
    # Collection of events.
    class EventHash < Immutable::Hash
      def push_event(observer_class, event_name, data)
        observer_events = self[observer_class] || Immutable::EmptyHash
        name_events = observer_events[event_name] || Immutable::EmptyVector
        name_events = name_events.add(data)
        observer_events = observer_events.put(event_name, name_events)
        put(observer_class, observer_events)
      end
    end

    EMPTY_EVENT_HASH = EventHash.new([])
  end
end
