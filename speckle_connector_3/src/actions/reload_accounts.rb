# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative 'load_saved_streams'

module SpeckleConnector3
  module Actions
    # Action to reload accounts from database.
    class ReloadAccounts < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, _data)
        puts 'Reload of Speckle accounts requested by plugin'
        new_speckle_state = state.speckle_state.with_accounts(Accounts.load_accounts)
        state = state.with_speckle_state(new_speckle_state)
        accounts_data = state.speckle_state.accounts
        state.with_add_queue('loadAccounts', accounts_data.to_json, [])
      end
    end
  end
end
