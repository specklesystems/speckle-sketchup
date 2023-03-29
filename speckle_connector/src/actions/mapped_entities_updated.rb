# frozen_string_literal: true

require_relative 'action'
require_relative '../sketchup_model/reader/speckle_entities_reader'

module SpeckleConnector
  module Actions
    # Triggers when mapped entities updated.
    class MappedEntitiesUpdated < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _data = nil)
        mapped_entities = SketchupModel::Reader::SpeckleEntitiesReader
                          .mapped_entity_details(state.speckle_state.mapped_entities.values.to_a)

        state.with_mapped_entities_queue(mapped_entities)
      end
    end
  end
end
