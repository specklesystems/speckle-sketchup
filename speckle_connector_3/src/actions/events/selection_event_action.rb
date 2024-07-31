# frozen_string_literal: true

require_relative 'event_action'
require_relative '../mapper_selection_changed'
require_relative '../selection_actions/get_selection'
require_relative '../../mapper/category/revit_category'
require_relative '../../sketchup_model/reader/speckle_entities_reader'
require_relative '../../sketchup_model/reader/mapper_reader'
require_relative '../../sketchup_model/query/entity'

module SpeckleConnector3
  module Actions
    module Events
      # Update selected speckle objects when the selection changes for mapper tool.
      class SelectionEventAction < EventAction
        # @param state [States::State] the current state of Speckle application.
        # @return [States::State] the new updated state object
        def self.update_state(state, event_data)
          return state unless event_data&.any?

          # POC: Not happy with it. We log also entity.entityID property since
          # onElementRemoved observer only return them! :/ Reconsider this in BETA!
          selected_object_ids = state.sketchup_state.sketchup_model.selection.collect(&:persistent_id) +
                                state.sketchup_state.sketchup_model.selection.collect(&:entityID)
          summary = "Selected #{selected_object_ids.length / 2} objects." # POC: OFFF. I'll fix it
          selection_info = UiData::Sketchup::SelectionInfo.new(selected_object_ids, summary)
          js_script = "selectionBinding.emit('setSelection', #{selection_info.to_json})"
          state.with_add_queue_js_command('setSelection', js_script)

          # Collect and return mapper selection info.
          # Later we can add more selection info for different scopes.
          # MapperSelectionChanged.new(sketchup_selection).update_state(state)
        end
      end
    end
  end
end
