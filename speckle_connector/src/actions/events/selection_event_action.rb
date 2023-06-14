# frozen_string_literal: true

require_relative 'event_action'
require_relative '../../mapper/category/revit_category'
require_relative '../../sketchup_model/reader/speckle_entities_reader'
require_relative '../../sketchup_model/query/entity'

module SpeckleConnector
  module Actions
    module Events
      # Update selected speckle objects when the selection changes for mapper tool.
      class SelectionEventAction < EventAction
        # @param state [States::State] the current state of Speckle application.
        # @return [States::State] the new updated state object
        def self.update_state(state, event_data)
          return state unless event_data&.any?

          sketchup_selection = state.sketchup_state.sketchup_model.selection
          selection = {
            selection: SketchupModel::Reader::SpeckleEntitiesReader.entities_schema_details(sketchup_selection),
            mappingMethods: [
              'Direct Shape'
            ],
            categories: Mapper::Category::RevitCategory.to_a
          }
          selection = { selection: [], mappingMethods: [], categories: [] } if sketchup_selection.none?

          state.with_selection_queue(selection)
        end
      end
    end
  end
end
