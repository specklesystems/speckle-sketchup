# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector3
  module Actions
    # Test purpose action.
    class TriggerEvent < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, event_name)
        if event_name == 'emptyTestEvent'
          js_script = "testBinding.emit('#{event_name}')"
        else
          args = {
            name: 'Oguzhan',
            isOk: true,
            count: 3
          }
          js_script = "testBinding.emit('#{event_name}', #{args.to_json})"
        end
        resolve_js_script = "testBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('triggerEventResolve', resolve_js_script)
        state.with_add_queue_js_command('triggerEvent', js_script)
      end
    end
  end
end
