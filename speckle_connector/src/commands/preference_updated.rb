# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../actions/preference_updated'

module SpeckleConnector
  module Commands
    # Command to update preferences.
    class PreferenceUpdated < Command
      def _run(data)
        preference_hash = data['preference_hash']
        preference = data['preference']
        new_value = data['value']
        app.update_state!(Actions::PreferenceUpdated.new(preference_hash, preference, new_value))
      end
    end
  end
end
