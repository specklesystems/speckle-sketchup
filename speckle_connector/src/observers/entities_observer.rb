# frozen_string_literal: true

require_relative 'event_observer'

module SpeckleConnector
  module Observers
    # Entities observer.
    class EntitiesObserver < Sketchup::EntitiesObserver
      include EventObserver

      # rubocop:disable Naming/MethodName
      # @param entities (Sketchup::Entities)
      # @param entity (Sketchup::Entity)
      def onElementAdded(entities, entity)
        puts "onElementAdded"
        push_event(:onElementAdded, entities, entity)
      end

      # @param entities (Sketchup::Entities)
      # @param entity (Sketchup::Entity)
      def onElementModified(entities, entity)
        puts "onElementModified"
        push_event(:onElementModified, entities, entity)
      end

      # @param entities (Sketchup::Entities)
      # @param entity_id (Integer) id of the removed entity.
      def onElementRemoved(entities, entity_id)
        puts "onElementRemoved"
        push_event(:onElementRemoved, entities, entity_id)
      end
      # rubocop:enable Naming/MethodName
    end
  end
end
