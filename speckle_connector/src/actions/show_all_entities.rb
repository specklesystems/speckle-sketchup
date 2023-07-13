# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Show all entities on the model.
    class ShowAllEntities < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _resolve_id, _data)
        # Show all entities first
        state.sketchup_state.sketchup_model.entities.each do |ent|
          ent.hidden = false
        end
        state
      end
    end
  end
end
