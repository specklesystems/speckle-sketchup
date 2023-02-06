# frozen_string_literal: true

require_relative 'observable'

module SpeckleConnector
  module Observers
    class ModelObserver < Sketchup::ModelObserver
      include Observable

      # @param model (Sketchup::Model)
      def onActivePathChanged(model)
        push_event(:onActivePathChanged, model)
      end
    end
  end
end
