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
      def self.update_state(state, _data)
        puts 'Initialisation of Speckle accounts requested by plugin'
        accounts_data = state.speckle_state.accounts
        # state.with_add_queue('bindings.receiveResponse', accounts_data.to_json, [])
        js_command = "bindings.receiveResponse('#{_data[:request_id]}', '#{accounts_data.to_json}')"
        puts js_command
        state.with_add_queue_js_command('init_local_accounts', js_command)
      end
    end
  end
end
