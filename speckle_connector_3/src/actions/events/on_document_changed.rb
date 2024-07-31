# frozen_string_literal: true

module SpeckleConnector3
  module Actions
    # Triggers whenever document has changed.
    class OnDocumentChanged < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        js_command = "baseBinding.emit('documentChanged')"
        state.with_add_queue_js_command('documentChanged', js_command)
      end
    end
  end
end
