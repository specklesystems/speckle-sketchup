# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector3
  module Actions
    # Action to let sketchup know receive will be started.
    class BeforeReceive < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, stream_id, root_id)
        puts "receive started for: #{root_id}"
        js_script = "sketchupReceiveBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('beforeReceive', js_script)
      end
    end
  end
end
