# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Get document info.
    class GetDocumentInfo < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, _data)
        document_info = {
          location: state.sketchup_state.sketchup_model.path,
          name: state.sketchup_state.sketchup_model.name,
          id: state.sketchup_state.sketchup_model.guid
        }
        js_command = "baseBinding.receiveResponse('#{resolve_id}', #{document_info.to_json})"
        state.with_add_queue_js_command('getDocumentInfo', js_command)
      end
    end
  end
end
