# frozen_string_literal: true

require 'json'
require_relative '../action'

module SpeckleConnector3
  module Actions
    # Answers an authenticateAccount call with the account its sign-in saved.
    class CompleteAuthenticateAccount < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @param resolve_id [String] request id of the authenticateAccount call
      # @param account [Hash] the account as saved into Accounts.db
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, account)
        js_script = "accountsBinding.receiveResponse('#{resolve_id}', #{account.to_json})"
        state.with_add_queue_js_command("authenticateAccount_#{resolve_id}", js_script)
      end
    end
  end
end
