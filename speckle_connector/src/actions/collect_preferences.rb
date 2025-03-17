# frozen_string_literal: true

require_relative 'action'
require_relative '../ext/sqlite3'
require_relative '../constants/path_constants'

module SpeckleConnector
  module Actions
    # Action to collect preferences from database to UI.
    class CollectPreferences < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, _data)
        state.with_add_queue('collectPreferences', state.user_state.preferences.to_json, [])
      end
    end
  end
end
