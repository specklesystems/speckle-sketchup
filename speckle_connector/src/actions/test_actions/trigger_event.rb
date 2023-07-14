# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Test purpose action.
    class TriggerEvent < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, event_name)
        if event_name == 'emptyTestEvent'
          js_script = "testBindings.emit('#{event_name}')"
        else
          args = {
            name: 'Oguzhan',
            isOk: true,
            count: 3
          }
          js_script = "testBindings.emit('#{event_name}', #{args.to_json})"
        end
        state.with_add_queue_js_command('triggerEvent', js_script)
      end
    end
  end
end
