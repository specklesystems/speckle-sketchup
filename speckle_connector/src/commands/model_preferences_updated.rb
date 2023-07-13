# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../actions/model_preference_updated'

module SpeckleConnector
  module Commands
    # Command to update theme.
    class ModelPreferencesUpdated < Command
      def _run(_resolve_id, data)
        preference = data['preference']
        new_value = data['value']
        app.update_state!(Actions::ModelPreferencesUpdated.new(preference, new_value))
      end
    end
  end
end
