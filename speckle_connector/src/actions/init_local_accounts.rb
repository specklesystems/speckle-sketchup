# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative 'load_saved_streams'

module SpeckleConnector3
  module Actions
    # Action to initialize local accounts from database.
    class InitLocalAccounts < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _request_id, _data)
        puts 'Initialisation of Speckle accounts requested by plugin'
        accounts_data = state.speckle_state.accounts
        state.with_add_queue('loadAccounts', accounts_data.to_json, [])
      end
    end
  end
end
