# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Get commands.
    class GetCommands < Action
      def initialize(commands)
        super()
        @commands = commands
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        commands_string = JSON.generate(@commands)
        js = "bindings.receiveCommandsAndInitializeBridge('#{commands_string}')"
        state.with_add_queue_js_command('getCommands', js)
      end
    end
  end
end
