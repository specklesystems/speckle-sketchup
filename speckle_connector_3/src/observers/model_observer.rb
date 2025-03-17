# frozen_string_literal: true

require_relative 'event_observer'

module SpeckleConnector3
  module Observers
    # Model related event observers.
    class ModelObserver < Sketchup::ModelObserver
      include EventObserver

      # rubocop:disable Naming/MethodName
      # @param model (Sketchup::Model)
      def onActivePathChanged(model)
        push_event(:onActivePathChanged, model)
      end
      # rubocop:enable Naming/MethodName
    end
  end
end
