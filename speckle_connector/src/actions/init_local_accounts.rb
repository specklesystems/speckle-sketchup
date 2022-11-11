# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative 'load_saved_streams'

module SpeckleConnector
  module Actions
    # Action to initialize local accounts from database.
    class InitLocalAccounts < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, data)
        puts 'Initialisation of Speckle accounts requested by plugin'
        accounts_data = Accounts.load_accounts.to_json
        state = state.with_add_queue('loadAccounts', accounts_data, [])
        Actions::LoadSavedStreams.update_state(state, data)
      end
    end
  end
end
