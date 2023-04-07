# frozen_string_literal: true

require_relative 'action'
require_relative 'events/selection_event_action'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  module Actions
    # Isolate entities that selected from mapped elements table.
    class IsolateMappingsFromTable < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, data)
        sketchup_model = state.sketchup_state.sketchup_model
        # Flat entities to clear mappings
        comp_flat_entities = SketchupModel::Query::Entity.flat_entities(
          sketchup_model.entities, [Sketchup::ComponentInstance, Sketchup::Group]
        )
        flat_entities = SketchupModel::Query::Entity.flat_entities(sketchup_model.entities)

        # Collect entity ids to clear mappings
        selected_elements = data.collect { |_, entities| entities['selectedElements'] }.flatten

        comps_or_groups, faces_or_edges = selected_elements.partition do |e|
          e['entityType'] == 'Component' || e['entityType'] == 'Group'
        end

        entity_ids = faces_or_edges.collect { |e| e['entityId'] }

        comps_or_groups.each do |e|
          entity = comp_flat_entities.find { |flat_e| flat_e.persistent_id == e['entityId'] }
          entities_for_definition = SketchupModel::Query::Entity.flat_entities(entity.definition.entities)
          entity_ids += entities_for_definition.collect(&:persistent_id) + [entity.persistent_id]
        end

        # Store speckle state to update with mapped entities.
        flat_entities.each do |entity|
          next if entity_ids.include?(entity.persistent_id)

          entity.hidden = true
        end

        Events::SelectionEventAction.update_state(state, { clear: true })
      end
    end
  end
end
