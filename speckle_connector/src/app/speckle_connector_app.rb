# frozen_string_literal: true

require_relative '../actions/clear_queue'

module SpeckleConnector
  module App
    # Application for the Speckle Connector.
    class SpeckleConnectorApp
      # @return [Commands::MenuCommandHandler] the commands registered in the extension menu in Sketchup
      attr_reader :menu_commands

      # @return [States::State] the current states of the app
      attr_reader :state

      # @return [Ui::UiController] controller for ui views
      attr_reader :ui_controller

      # @return [Observers::Handler] the observers indexed by their classes to handle
      attr_reader :observer_handler

      def initialize(menu_commands, state, ui_controller)
        @menu_commands = menu_commands
        @state = state
        @ui_controller = ui_controller
      end

      def speckle_loaded?
        state.speckle_state?
      end

      # Attach observers to application when speckle initialized via menu commands.
      def add_observer_handler!(observer_handler)
        @observer_handler = observer_handler
      end

      # Send messages to HtmlDialog if any.
      def send_messages!
        queue = @state.speckle_state.message_queue
        queue.each_value do |value|
          instant_message_sender(value)
        end
        update_state!(Actions::ClearQueue)
      end

      def instant_message_sender(message)
        ui_controller.user_interfaces.each_value do |dialog|
          dialog.execute_script(message)
        end
      end

      # This is the only function application state will be switched by calling upcoming action with it's parameters
      #  if any.
      def update_state!(action, *parameters)
        old_state = @state
        @state = action.update_state(old_state, *parameters)
        send_messages! if @state.speckle_state.message_queue.any?
      end
    end
  end
end
