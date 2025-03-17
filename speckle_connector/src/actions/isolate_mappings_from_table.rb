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
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def self.update_state(state, _resolve_id, data)
        sketchup_model = state.sketchup_state.sketchup_model

        # Hide all entities first
        sketchup_model.entities.each do |ent|
          ent.hidden = true
        end

        # Flat entities to isolate mappings
        flat_entities = SketchupModel::Query::Entity.flat_entities(sketchup_model.entities)

        comp_flat_entities = flat_entities.grep(Sketchup::ComponentInstance) + flat_entities.grep(Sketchup::Group) +
                             flat_entities.grep(Sketchup::ComponentDefinition)
        face_edge_flat_entities = flat_entities.grep(Sketchup::Face) + flat_entities.grep(Sketchup::Edge)

        # Collect entity ids to clear mappings
        selected_elements = data.collect { |_, entities| entities['selectedElements'] }.flatten

        comps_or_groups, faces_or_edges = selected_elements.partition do |e|
          e['entityType'] == 'Component' || e['entityType'] == 'Definition' || e['entityType'] == 'Group'
        end

        faces_or_edges_ids = faces_or_edges.collect { |e| e['entityId'] }

        face_edge_flat_entities.select { |e| faces_or_edges_ids.include?(e.persistent_id) }.each do |entity|
          entity.hidden = false
        end

        comps_or_groups_ids = comps_or_groups.collect { |e| e['entityId'] }

        comp_flat_entities.select { |e| comps_or_groups_ids.include?(e.persistent_id) }.each do |entity|
          if entity.is_a?(Sketchup::ComponentDefinition)
            entity.instances.each do |instance|
              instance.hidden = false
            end
          end
          entity.hidden = false
        end

        Events::SelectionEventAction.update_state(state, { clear: true })
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
