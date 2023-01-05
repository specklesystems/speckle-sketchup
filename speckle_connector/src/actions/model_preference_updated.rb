# frozen_string_literal: true

require_relative 'action'
require_relative '../ext/sqlite3'
require_relative '../accounts/accounts'
require_relative '../constants/path_constants'
require_relative '../sketchup_model/dictionary/speckle_model_dictionary_handler'

module SpeckleConnector
  module Actions
    # When preference updated by UI.
    class ModelPreferencesUpdated < Action
      def initialize(pref, value)
        super()
        @preference = pref
        @value = value
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        model = state.user_state.preferences[:model].dup
        model[@preference.to_sym] = @value
        new_preferences = state.user_state.preferences.put(:model, model)
        SketchupModel::Dictionary::SpeckleModelDictionaryHandler.set_attribute(
          state.sketchup_state.sketchup_model,
          @preference.to_sym,
          @value,
          'Speckle'
        )
        new_user_state = state.user_state.with_preferences(new_preferences)
        state.with_user_state(new_user_state)
      end
    end
  end
end
