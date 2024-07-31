# frozen_string_literal: true

require_relative 'action'
require_relative '../ext/sqlite3'
require_relative '../accounts/accounts'
require_relative '../constants/path_constants'

module SpeckleConnector3
  module Actions
    # When preference updated by UI.
    class UserPreferencesUpdated < Action
      def initialize(pref_hash, pref, value)
        super()
        @preference_hash = pref_hash
        @preference = pref
        @value = value
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def update_state(state)
        # Init sqlite database
        db = Sqlite3::Database.new(SPECKLE_CONFIG_DB_PATH)

        # Select data
        data = db.exec("SELECT content FROM 'objects' WHERE hash = '#{@preference_hash}'").first.first

        # Parse string to hash
        data_hash = JSON.parse(data).to_h

        # Get current preference value
        old_preference_value = data_hash[@preference]

        # Return old state if it is equal to new one
        return state if @value == old_preference_value

        data_hash[@preference] = @value

        # Update entry unless equal old to new
        db.exec("UPDATE 'objects' SET content = '#{data_hash.to_json}' WHERE hash = '#{@preference_hash}'")

        # Close db when process done
        db.close

        user = state.user_state.preferences[:user].dup
        user[@preference.to_sym] = @value
        new_preferences = state.user_state.preferences.put(:user, user)
        new_user_state = state.user_state.with_preferences(new_preferences)
        # This is the place we can send information to UI for diffing check. It is a technical depth!
        if @preference == 'diffing'
          new_speckle_state = if @value
                                state.speckle_state.with_invalid_streams_queue
                              else
                                state.speckle_state.with_empty_invalid_streams_queue
                              end
          state = state.with_speckle_state(new_speckle_state)
        end
        state.with_user_state(new_user_state)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
