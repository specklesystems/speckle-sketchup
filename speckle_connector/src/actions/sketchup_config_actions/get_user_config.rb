# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Action to get user config.
    class GetUserConfig < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        # Previously it was stored in user state
        # config = state.user_state.preferences.to_json
        config = [
          {
            key: 'darkTheme',
            title: 'Theme',
            type: 'toggle',
            config: {
              value: state.user_state.user_preferences[:dark_theme]
            }
          },
          {
            key: 'diffing',
            title: 'Diffing',
            type: 'toggle',
            config: {
              value: state.user_state.user_preferences[:diffing]
            }
          },
          {
            key: 'referencePoint',
            title: 'Reference Point',
            type: 'dropdown',
            config: {
              value: 'test',
              items: ['test', 'test1', 'test2']
            }
          }
        ]
        js_script = "connectorConfigBinding.receiveResponse('#{resolve_id}', #{config.to_json})"
        state.with_add_queue_js_command('getUserConfig', js_script)
      end
    end
  end
end
