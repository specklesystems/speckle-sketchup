# frozen_string_literal: true

module SpeckleConnector
  module Commands
    # Base command schema to wrap common operations for all commands.
    class Command
      # @return [App::SpeckleConnectorApp] the main app object
      attr_reader :app

      # @return [Ui::View] view object holds dialog and it's state
      attr_reader :view

      # @@param app [App::SpeckleConnectorApp] the main app object
      def initialize(app)
        @app = app
        @view = app.ui_controller.user_interfaces[Ui::SPECKLE_UI_ID]
      end

      def run(*parameters)
        # Run here common operations that same for each command.
        with_observers_disabled do
          _run(*parameters)
        end
      end

      private

      def with_observers_disabled(&block)
        observer_handler = @app.observer_handler
        if observer_handler
          observer_handler.with_observers_disabled(&block)
        else
          block.call
        end
      end

      def _run(*_parameters)
        raise NotImplementedError, 'Implement in subclass'
      end
    end
  end
end
