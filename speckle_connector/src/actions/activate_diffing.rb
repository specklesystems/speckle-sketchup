# frozen_string_literal: true

require_relative 'action'
require_relative 'deactivate_diffing'

module SpeckleConnector
  module Actions
    # Deactivate diffing for stream.
    class ActivateDiffing < Action
      def initialize(stream_id)
        super()
        @stream_id = stream_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        state = DeactivateDiffing.update_state(state)
        puts "Diffing activated for #{@stream_id}"
        speckle_entities = state.speckle_state.speckle_entities
        invalid_speckle_entities = speckle_entities.select do |_id, entity|
          entity.invalid_stream_ids.include?(@stream_id) && entity.sketchup_entity.is_a?(Sketchup::Face)
        end
        invalid_speckle_entities.each do |id, entity|
          new_entity = entity.activate_diffing(@stream_id, state.sketchup_state.materials.by_id(MAT_EDIT))
          speckle_entities = speckle_entities.put(id, new_entity)
        end
        new_speckle_state = state.speckle_state.with_speckle_entities(speckle_entities)
        state.with_speckle_state(new_speckle_state)
      end
    end
  end
end
