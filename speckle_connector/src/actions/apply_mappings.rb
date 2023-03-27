# frozen_string_literal: true

require_relative 'action'
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
        entity = state.sketchup_state.sketchup_model.entities.find { |e| e.persistent_id == @entities_to_map.first }
        if @is_definition && (entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance))
          entity = entity.definition
        end
        SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :category, @category)
        SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :name, @name)
        SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.set_attribute(entity, :method, @method)
        state
      end
    end
  end
end
