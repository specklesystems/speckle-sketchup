# frozen_string_literal: true

require_relative 'event_observer'

module SpeckleConnector3
  module Observers
    # Entity observer.
    class EntityObserver < Sketchup::EntityObserver
      include EventObserver

      # rubocop:disable Naming/MethodName
      # @param entity (Sketchup::Entity)
      def onChangeEntity(entity)
        puts "onChangeEntity: #{entity}"
        push_event(:onChangeEntity, entity)
      end
      # rubocop:enable Naming/MethodName
    end
  end
end
