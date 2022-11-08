# frozen_string_literal: true

require_relative 'command'

module SpeckleConnector
  module Commands
    class ActionCommand < Command
      # @param app [App::SpeckleConnectorApp] the app object to run command on
      # @param action [#update_state] the action that knows how to change the state of the speckle app
      def initialize(app, action, action_name)
        super(app, action_name)
        @app = app
        @action = action
      end

      private

      def _run(*parameters)
        app.update_state!(@action, *parameters)
      end
    end
  end
end
