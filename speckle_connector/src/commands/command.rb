# frozen_string_literal: true

require_relative '../actions/handle_error'

module SpeckleConnector
  module Commands
    # Base command schema to wrap common operations for all commands.
    class Command
      # @return [App::SpeckleConnectorApp] the main app object
      attr_reader :app

      # @return [Ui::Binding] binding object holds dialog and it's state
      attr_reader :binding

      # @param app [App::SpeckleConnectorApp] the main app object
      # @param binding [Ui::Binding] binding object holds commands to call
      def initialize(app, binding)
        @app = app
        @binding = binding
      end

      def run(*parameters)
        begin
          # Run here common operations that same for each command.
          with_observers_disabled do
            _run(*parameters)
          end
        rescue StandardError => e
          action = Actions::HandleError.new(e, @binding.name, @action, parameters)
          app.update_state!(action)
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
