# frozen_string_literal: true

require_relative 'action'
require_relative '../states/state'
require_relative '../states/speckle_state'
require_relative '../states/sketchup_state'
require_relative '../accounts/accounts'

module SpeckleConnector
  module Actions
    # Initialization of the real state of the speckle.
    class InitializeSpeckle < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        # FIXME: below is how supposed to be
        # accounts = Accounts.load_accounts.to_json
        accounts = {}
        speckle_state = States::SpeckleState.new(accounts, {}, {})
        # This should be the only point that `Sketchup_active_model` passed to application state.
        sketchup_state = States::SketchupState.new(Sketchup.active_model)
        States::State.new(state.user_state, speckle_state, sketchup_state, false)
      end
    end
  end
end
