# frozen_string_literal: true

require_relative '../action'
require_relative '../../preferences/preferences'

module SpeckleConnector3
  module Actions
    class SetUserSelectedAccountId < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, account_id)
        Preferences.set_user_selected_account_id(account_id)
        js_script = "configBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('setUserSelectedAccountId', js_script)
      end
    end
  end
end
