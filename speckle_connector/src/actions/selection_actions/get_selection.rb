# frozen_string_literal: true

require_relative '../action'
require_relative '../../ui_data/sketchup/selection_info'

module SpeckleConnector3
  module Actions
    # Action to get selection.
    class GetSelection < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        # POC: Not happy with it. We log also entity.entityID property since
        # onElementRemoved observer only return them! :/ Reconsider this in BETA!
        selected_object_ids = state.sketchup_state.sketchup_model.selection.collect(&:persistent_id) +
                              state.sketchup_state.sketchup_model.selection.collect(&:entityID) # That's bad
        summary = "Selected #{selected_object_ids.length / 2} objects." # POC: OFFF. I'll fix it
        selection_info = UiData::Sketchup::SelectionInfo.new(selected_object_ids, summary)
        js_script = "selectionBinding.receiveResponse('#{resolve_id}', #{selection_info.to_json})"
        state.with_add_queue_js_command('getSelection', js_script)
      end
    end
  end
end
