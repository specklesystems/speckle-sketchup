# frozen_string_literal: true

module SpeckleConnector
  module Actions
    # Triggers whenever document has changed.
    class OnDocumentChanged < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        document_info = {
          location: state.sketchup_state.sketchup_model.path,
          name: state.sketchup_state.sketchup_model.name,
          id: state.sketchup_state.sketchup_model.guid
        }
        js_command = "baseBinding.emit('documentChanged', #{JSON.unparse(document_info.to_json)})"
        state.with_add_queue_js_command('getDocumentInfo', js_command)
      end
    end
  end
end
