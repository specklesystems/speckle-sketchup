# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative 'load_saved_streams'

module SpeckleConnector
  module Actions
    # Action to initialize local accounts from database.
    class GetAccounts < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        puts 'Initialisation of Speckle accounts requested by plugin'
        accounts_data = state.speckle_state.accounts
        js_script = "accountsBinding.receiveResponse('#{resolve_id}', #{accounts_data.to_json})"
        state.with_add_queue_js_command('getAccounts', js_script)
      end
    end
  end
end
