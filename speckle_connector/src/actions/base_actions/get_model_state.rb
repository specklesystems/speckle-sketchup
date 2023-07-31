# frozen_string_literal: true

require_relative '../action'
require_relative '../../filters/send_filters'

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
              projectId: 'Sketchup',
              modelId: 'Saved',
              filters: Filters::SendFilters.get_default(state.sketchup_state.sketchup_model),
              activeFilters: ['everything']
            },
            {
              projectId: 'Sketchup',
              modelId: 'Saved-2',
              filters: Filters::SendFilters.get_default(state.sketchup_state.sketchup_model),
              activeFilters: ['selection', 'tags']
            }
          ]
        }
        js_script = "baseBinding.receiveResponse('#{resolve_id}', #{model_state.to_json})"
        state.with_add_queue_js_command('getModelState', js_script)
      end
    end
  end
end
