# frozen_string_literal: true

module SpeckleConnector
  module Commands
    # Base command schema to wrap common operations for all commands.
    class Command
      # @return [App::SpeckleConnectorApp] the main app object
      attr_reader :app

      # @return [String] name of the command
      attr_reader :command_name

      # @return [Ui::View] view object holds dialog and it's state
      attr_reader :view

      # @@param app [App::SpeckleConnectorApp] the main app object
      def initialize(app, command_name)
        @app = app
        @view = app.ui_controller.user_interfaces[Ui::SPECKLE_UI_ID]
        @command_name = command_name
      end

      def run(*parameters)
        # Run here common operations that same for each command.
        _run(*parameters)
      end

      private

      def _run(*parameters)
        raise NotImplementedError, 'Implement in subclass'
      end
    end
  end
end
