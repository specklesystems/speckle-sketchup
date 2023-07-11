# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    class GetSourceAppName < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _data)
        js_command = "bindings.receiveResponse('#{_data[:request_id]}', 'Sketchup')"
        puts js_command
        state.with_add_queue_js_command('getSourceAppName', js_command)
      end
    end
  end
end
