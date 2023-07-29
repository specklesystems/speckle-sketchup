# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Action to update send filter.
    class UpdateSendFilter < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, project_id, model_id, filter_id, filter)
        puts "Project id: #{project_id}"
        puts "Model id: #{model_id}"
        puts "Filter id: #{filter_id}"
        puts "Filter: #{filter}"
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('updateSendFilter', js_script)
      end
    end
  end
end
