# frozen_string_literal: true

require_relative '../action'
require_relative '../user_preferences_updated'

module SpeckleConnector
  module Actions
    # Action to update config.
    class UpdateConfig < Action
      KEY_VALUES = {
        'darkTheme' => 'dark_theme'
      }.freeze

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, config)
        config.each do |key, value|
          state = Actions::UserPreferencesUpdated.new('configSketchup', KEY_VALUES[key], value).update_state(state)
        end

        js_script = "configBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('updateConfig', js_script)
      end
    end
  end
end
