# frozen_string_literal: true

require_relative 'action'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Clear mapper source.
    class ClearMapperSource < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, _data)
        new_speckle_state = state.speckle_state.with_removed_mapper_source
        erase_levels(state)
        state.with_speckle_state(new_speckle_state)
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      def self.erase_levels(state)
        levels = state.sketchup_state.sketchup_model.definitions.select do |definition|
          SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.get_attribute(definition, :speckle_type) ==
            OBJECTS_BUILTELEMENTS_REVIT_LEVEL
        end
        levels.each do |level|
          level.entities.clear!
          level.instances.each(&:erase!)
        end
      end
    end
  end
end
