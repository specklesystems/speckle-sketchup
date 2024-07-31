# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector3
  module Actions
    # Test purpose action.
    class GoAway < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        puts 'SketchUp went away :('
        js_script = "testBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('goAway', js_script)
      end
    end
  end
end
