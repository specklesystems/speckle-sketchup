# frozen_string_literal: true

require_relative 'event_observer'

module SpeckleConnector
  module Observers
    # @see https://ruby.sketchup.com/Sketchup/SelectionObserver.html
    class SelectionObserver < Sketchup::SelectionObserver
      include EventObserver

      # rubocop:disable Naming/MethodName
      # @param _selection (Sketchup::Selection)
      # @param _entity (Sketchup::Entity)
      def onSelectionAdded(_selection, _entity)
        push_selection_event(:onSelectionAdded)
      end

      # @param _selection (Sketchup::Selection)
      def onSelectionBulkChange(_selection)
        push_selection_event(:onSelectionBulkChange)
      end

      # @param _selection (Sketchup::Selection)
      def onSelectionCleared(_selection)
        push_selection_event(:onSelectionCleared)
      end

      # @param _selection (Sketchup::Selection)
      def onSelectionRemoved(_selection, _entity)
        push_selection_event(:onSelectionRemoved)
      end

      # Due to a SketchUp bug, this method is called by the wrong name.
      alias onSelectedRemoved onSelectionRemoved
      # rubocop:enable Naming/MethodName

      private

      # Selection changes need to be registered only once
      def push_selection_event(event_name)
        # Don't push anything if the selection event was already registered
        selection_events = observer_handler.events[self.class]
        return if selection_events&.any?

        push_event(event_name)
      end
    end
  end
end
