# frozen_string_literal: true

module SpeckleConnector
  module Ui
    # The class that handle communication between ruby code and different user interfaces.
    class UiController
      # @return [Immutable::Hash] the registered user interfaces that will receive notifications when Speckle states
      #  is updated.
      attr_reader :user_interfaces

      # @return [Ui::SketchupUi] the interface to Sketchup UI features
      attr_reader :sketchup_ui

      # @param sketchup_ui [Ui::SketchupUi] the interface to Sketchup UI features
      def initialize(sketchup_ui)
        @user_interfaces = {}
        @sketchup_ui = sketchup_ui
      end

      # Register user interface to receive notifications about states changes
      def register_ui(interface_id, user_interface)
        # FIXME: Mutable alert!
        @user_interfaces[interface_id] = user_interface
      end

      # Update user interfaces with new speckle states object
      def update_ui(state)
        user_interfaces.each_value do |ui|
          ui.update_view(state)
        end
      end
    end
  end
end
