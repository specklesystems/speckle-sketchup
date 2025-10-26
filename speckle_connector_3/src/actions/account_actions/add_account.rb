# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../load_saved_streams'

module SpeckleConnector3
  module Actions
    # Action to add account to local Account db.
    class AddAccount < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, account_id, account)
        SpeckleConnector3::Accounts.add_account(account_id, account)
        js_script = "accountsBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('addAccount', js_script)
      end
    end
  end
end
