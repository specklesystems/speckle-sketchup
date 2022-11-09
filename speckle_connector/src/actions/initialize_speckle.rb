# frozen_string_literal: true

require_relative 'action'
require_relative '../states/state'
require_relative '../states/speckle_state'
require_relative '../accounts/accounts'

module SpeckleConnector
  module Actions
    class InitializeSpeckle < Action
      def self.update_state(state)
        # FIXME: below is how supposed to be
        # accounts = Accounts.load_accounts.to_json
        accounts = {}
        speckle_state = States::SpeckleState.new(accounts, {})
        States::State.new(state.user_state, speckle_state, false)
      end
    end
  end
end
