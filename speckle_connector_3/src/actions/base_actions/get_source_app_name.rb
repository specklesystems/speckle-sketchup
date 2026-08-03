# frozen_string_literal: true

require_relative '../action'
require_relative '../../constants/app_constants'

module SpeckleConnector3
  module Actions
    # Get source app name.
    class GetSourceAppName < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        js_command = "baseBinding.receiveResponse('#{resolve_id}', '#{HOST_APP_SLUG}')"
        state.with_add_queue_js_command('getSourceAppName', js_command)
      end
    end
  end
end
