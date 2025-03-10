# frozen_string_literal: true

require_relative '../action'
require_relative '../../preferences/preferences'

module SpeckleConnector3
  module Actions
    class GetUserSelectedAccountId < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        user_selected_account_id = Preferences.get_user_selected_account_id
        accountsConfig = {
          userSelectedAccountId: user_selected_account_id
        }
        js_script = "configBinding.receiveResponse('#{resolve_id}', #{accountsConfig.to_json})"
        state.with_add_queue_js_command('getUserSelectedAccountId', js_script)
      end
    end
  end
end
