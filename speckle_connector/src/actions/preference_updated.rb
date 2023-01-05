# frozen_string_literal: true

require_relative 'action'
require_relative '../ext/sqlite3'
require_relative '../accounts/accounts'
require_relative '../constants/path_constants'

module SpeckleConnector
  module Actions
    # When preference updated by UI.
    class PreferenceUpdated < Action
      def initialize(pref_hash, pref, value)
        super()
        @preference_hash = pref_hash
        @preference = pref
        @value = value
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
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

        state
      end
    end
  end
end
