# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Action to get config.
    class GetConfig < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        # Previously it was stored in user state
        # config = state.user_state.preferences.to_json
        config = {
          darkTheme: state.user_state.user_preferences[:dark_theme]
        }
        js_script = "configBinding.receiveResponse('#{resolve_id}', #{config.to_json})"
        state.with_add_queue_js_command('getConfig', js_script)
      end
    end
  end
end
