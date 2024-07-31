# frozen_string_literal: true

require_relative 'action'
require_relative 'mapped_entities_updated'
require_relative 'events/selection_event_action'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Apply mappings for selected entities.
    class ApplyMappings < Action
      def initialize(entities_to_map, method, category, family,
                     family_type, level, name, is_definition)
        super()
        @entities_to_map = entities_to_map
        @method = method
        @category = category
        @name = name
        @family = family
        @family_type = family_type
        @level = level
        @is_definition = is_definition
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/MethodLength
      def update_state(state)
        sketchup_model = state.sketchup_state.sketchup_model
        entities = if sketchup_model.active_path.nil?
                     sketchup_model.entities
                   else
                     sketchup_model.active_path.last.definition.entities
                   end

        # Collect entities from entity ids that comes from UI as list
        entities_to_map = entities.select { |e| @entities_to_map.include?(e.persistent_id) }

        # Switch to definitions if all entities are component instance and UI flag shows that
        if entities_to_map.all? { |e| e.is_a?(Sketchup::ComponentInstance) } && @is_definition
          entities_to_map = entities_to_map.collect(&:definition).uniq
        end

        # Store speckle state to update with mapped entities.
        speckle_state = state.speckle_state
        entities_to_map.each do |entity|
          name = if @name == '<Mixed>'
                   entity.respond_to?(:name) ? entity.name : ''
                 else
                   @name
                 end
          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :category, @category)
          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :name, name)
          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :method, @method)
          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :family, @family)
          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :family_type, @family_type)
          SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :level, @level)
          speckle_state = speckle_state.with_mapped_entity(entity)
        end

        new_state = MappedEntitiesUpdated.update_state(state.with_speckle_state(speckle_state))
        Events::SelectionEventAction.update_state(new_state, { apply: true })
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/MethodLength
    end
  end
end
