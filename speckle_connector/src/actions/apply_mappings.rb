# frozen_string_literal: true

require_relative 'action'
require_relative 'mapped_entities_updated'
require_relative 'events/selection_event_action'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  module Actions
    # Apply mappings for selected entities.
    class ApplyMappings < Action
      def initialize(entities_to_map, method, category, name, is_definition)
        super()
        @entities_to_map = entities_to_map
        @method = method
        @category = category
        @name = name
        @is_definition = is_definition
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        sketchup_model = state.sketchup_state.sketchup_model
        entities = if sketchup_model.active_path.nil?
                     sketchup_model.entities
                   else
                     sketchup_model.active_path.last.definition.entities
                   end
        entity = entities.find { |e| e.persistent_id == @entities_to_map.first }
        if @is_definition && (entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance))
          entity = entity.definition
        end
        SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :category, @category)
        SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :name, @name)
        SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :method, @method)
        new_speckle_state = state.speckle_state.with_mapped_entity(entity)
        new_state = MappedEntitiesUpdated.update_state(state.with_speckle_state(new_speckle_state))
        Events::SelectionEventAction.update_state(new_state, { apply: true })
      end
    end
  end
end
