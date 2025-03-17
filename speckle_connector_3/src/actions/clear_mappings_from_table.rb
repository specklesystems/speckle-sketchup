# frozen_string_literal: true

require_relative 'action'
require_relative 'mapped_entities_updated'
require_relative 'events/selection_event_action'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Clear mappings for selected entities from mapped elements table.
    class ClearMappingsFromTable < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, data)
        # Flat entities to clear mappings
        flat_entities = SketchupModel::Query::Entity.flat_entities(state.sketchup_state.sketchup_model.entities)

        # Collect entity ids to clear mappings
        entity_ids = data.collect { |_, entities| entities['selectedElements'].collect { |e| e['entityId'] } }.flatten
        # Store speckle state to update with mapped entities.
        speckle_state = state.speckle_state
        flat_entities.each do |entity|
          next unless entity_ids.include?(entity.persistent_id.to_s)

          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.remove_dictionary(entity)
          speckle_state = speckle_state.with_removed_mapped_entity(entity)
        end

        new_state = MappedEntitiesUpdated.update_state(state.with_speckle_state(speckle_state))
        Events::SelectionEventAction.update_state(new_state, { clear: true })
      end
    end
  end
end
