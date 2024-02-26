# frozen_string_literal: true

require_relative '../action'
require_relative '../../ui_data/sketchup/selection_info'

module SpeckleConnector
  module Actions
    # Action to get selection.
    class GetSelection < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        selected_object_ids = state.sketchup_state.sketchup_model.selection.collect(&:persistent_id)
        summary = "Selected #{selected_object_ids.length} objects."
        selection_info = UiData::Sketchup::SelectionInfo.new(selected_object_ids, summary)
        js_script = "selectionBinding.receiveResponse('#{resolve_id}', #{selection_info.to_json})"
        state.with_add_queue_js_command('getSelection', js_script)
      end
    end
  end
end
