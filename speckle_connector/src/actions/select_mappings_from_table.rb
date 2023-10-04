# frozen_string_literal: true

require_relative 'action'
require_relative 'events/selection_event_action'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  module Actions
    # Select entities that selected from mapped elements table.
    class SelectMappingsFromTable < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, data)
        # Clear first selection
        state.sketchup_state.sketchup_model.selection.clear

        # Flat entities to select mapped elements
        flat_entities = SketchupModel::Query::Entity.flat_entities(state.sketchup_state.sketchup_model.entities)

        # Collect entity ids to clear mappings
        entity_ids = data.collect { |_, entities| entities['selectedElements'].collect { |e| e['entityId'] } }.flatten

        # Store speckle state to update with mapped entities.
        flat_entities.each do |entity|
          next unless entity_ids.include?(entity.persistent_id)

          if entity.is_a?(Sketchup::ComponentDefinition)
            state.sketchup_state.sketchup_model.selection.add(entity.instances)
          end
          state.sketchup_state.sketchup_model.selection.add(entity)
        end

        Events::SelectionEventAction.update_state(state, { clear: true })
      end
    end
  end
end
