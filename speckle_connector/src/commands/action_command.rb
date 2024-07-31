# frozen_string_literal: true

require_relative 'command'

module SpeckleConnector3
  module Commands
    # Command to update state of the application.
    class ActionCommand < Command
      # @param app [App::SpeckleConnectorApp] the app object to run command on
      # @param binding [Ui::Binding] binding object holds commands to call
      # @param action [#update_state] the action that knows how to change the state of the speckle app
      def initialize(app, binding, action)
        super(app, binding)
        @action = action
      end

      private

      def _run(*parameters)
        app.update_state!(@action, *parameters)
      end
    end
  end
end
