# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    class SayHiFromRandom < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, arg1)
        js_script = "sketchupRandomBinding.receiveResponse('#{resolve_id}', '#{arg1}')"
        state.with_add_queue_js_command('sayHiFromRandom', js_script)
      end
    end
  end
end
