# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../actions/user_preferences_updated'

module SpeckleConnector3
  module Commands
    # Command to update preferences.
    class UserPreferencesUpdated < Command
      def _run(_resolve_id, data)
        preference_hash = data['preference_hash']
        preference = data['preference']
        new_value = data['value']
        app.update_state!(Actions::UserPreferencesUpdated.new(preference_hash, preference, new_value))
      end
    end
  end
end
