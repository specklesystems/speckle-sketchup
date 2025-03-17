# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector3
  module Actions
    # Action to get user config.
    class UpdateUserConfig < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, new_config)
        puts new_config.values
        js_script = "connectorConfigBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('updateUserConfig', js_script)
      end
    end
  end
end
