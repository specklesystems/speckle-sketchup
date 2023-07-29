# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Gets model state.
    class GetModelState < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        model_state = {
          sendCards: [
            {
              projectId: 'Sketchup Project',
              modelId: 'Sketchup Model'
            },
            {
              projectId: 'Sketchup Project 2',
              modelId: 'Sketchup Model 2'
            }
          ]
        }
        js_script = "baseBinding.receiveResponse('#{resolve_id}', #{model_state.to_json})"
        state.with_add_queue_js_command('getModelState', js_script)
      end
    end
  end
end
