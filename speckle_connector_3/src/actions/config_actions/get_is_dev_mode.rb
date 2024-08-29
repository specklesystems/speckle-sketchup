# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector3
  module Actions
    # Action to get is dev mode.
    class GetIsDevMode < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        js_script = "configBinding.receiveResponse('#{resolve_id}', #{DEV_MODE})"
        state.with_add_queue_js_command('getIsDevMode', js_script)
      end
    end
  end
end
