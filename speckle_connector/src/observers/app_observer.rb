# frozen_string_literal: true

require_relative 'observable'

module SpeckleConnector
  module Observers
    # App observer.
    class AppObserver < Sketchup::AppObserver
      include Observable

      # rubocop:disable Naming/MethodName
      # SketchUp observer method triggered when new empty model is created.
      #
      # @param model (Sketchup::Model): The active model object.
      def onNewModel(model)
        push_event(:onNewModel, model)
      end

      # SketchUp observer method triggered when previously saved model is opened.
      #
      # @param model (Sketchup::Model) - The active model object.
      def onOpenModel(model)
        push_event(:onOpenModel, model)
      end

      # SketchUp observer method triggered when user exists SketchUp.
      def onQuit
        push_event(:onQuit)
      end
      # rubocop:enable Naming/MethodName
    end
  end
end
