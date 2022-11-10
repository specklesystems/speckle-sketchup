# frozen_string_literal: true

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

      def initialize(menu_commands, state, ui_controller)
        @menu_commands = menu_commands
        @state = state
        @ui_controller = ui_controller
      end

      def speckle_loaded?
        state.speckle_state?
      end

      def update_ui!
        ui_controller.update_ui(state)
      end

      def update_state!(action, *parameters)
        old_state = @state
        @state = action.update_state(old_state, *parameters)
        update_ui! unless @state.equal?(old_state)
      end
    end
  end
end
