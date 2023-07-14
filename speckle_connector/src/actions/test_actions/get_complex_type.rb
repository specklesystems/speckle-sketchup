# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Test purpose action.
    class GetComplexType < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        complex_type = {
          id: 'complex_type_id',
          count: 3
        }
        js_script = "testBindings.receiveResponse('#{resolve_id}', #{complex_type.to_json})"
        state.with_add_queue_js_command('getComplexType', js_script)
      end
    end
  end
end
