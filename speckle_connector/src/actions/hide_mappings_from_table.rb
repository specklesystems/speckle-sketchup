# frozen_string_literal: true

require_relative 'action'
require_relative 'events/selection_event_action'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  module Actions
    # Hide entities that selected from mapped elements table.
    class HideMappingsFromTable < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, data)
        # Flat entities to clear mappings
        flat_entities = SketchupModel::Query::Entity.flat_entities(state.sketchup_state.sketchup_model.entities)

        # Collect entity ids to clear mappings
        entity_ids = data.collect { |_, entities| entities['selectedElements'].collect { |e| e['entityId'] } }.flatten

        # Store speckle state to update with mapped entities.
        flat_entities.each do |entity|
          next unless entity_ids.include?(entity.persistent_id)

          if entity.is_a?(Sketchup::ComponentDefinition)
            entity.instances.each do |instance|
              instance.hidden = true
            end
          end
          entity.hidden = true
        end

        Events::SelectionEventAction.update_state(state, { clear: true })
      end
    end
  end
end
