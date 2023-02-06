# frozen_string_literal: true

require_relative 'action'
require_relative '../states/state'
require_relative '../states/speckle_state'
require_relative '../states/sketchup_state'
require_relative '../accounts/accounts'
require_relative '../preferences/preferences'
require_relative '../constants/observer_constants'

module SpeckleConnector
  module Actions
    # Initialization of the real state of the speckle.
    class InitializeSpeckle < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, observers)
        attach_app_observer!(observers[APP_OBSERVER])
        accounts = SpeckleConnector::Accounts.load_accounts
        speckle_state = States::SpeckleState.new(accounts, observers, {}, {})
        # This should be the only point that `Sketchup_active_model` passed to application state.
        sketchup_state = States::SketchupState.new(Sketchup.active_model)
        preferences = Preferences.init_preferences(sketchup_state.sketchup_model)
        user_state_with_preferences = state.user_state.with_preferences(preferences)
        state = States::State.new(user_state_with_preferences, speckle_state, sketchup_state, false)
        Actions::LoadSketchupModel.update_state(state, sketchup_state.sketchup_model)
      end

      def self.attach_app_observer!(observer)
        Sketchup.add_observer(observer)
      end
    end
  end
end
