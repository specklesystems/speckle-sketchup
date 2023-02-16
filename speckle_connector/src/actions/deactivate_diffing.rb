# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Deactivate diffing.
    class DeactivateDiffing < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        puts 'Diffing deactivated!'
        speckle_entities = state.speckle_state.speckle_entities
        diffing_activated_speckle_entities = speckle_entities.reject do |_id, entity|
          entity.active_diffing_stream_id.nil?
        end
        diffing_activated_speckle_entities.each do |id, entity|
          new_entity = entity.deactivate_diffing
          speckle_entities = speckle_entities.put(id, new_entity)
        end
        new_speckle_state = state.speckle_state.with_speckle_entities(speckle_entities)
        state.with_speckle_state(new_speckle_state)
      end
    end
  end
end
