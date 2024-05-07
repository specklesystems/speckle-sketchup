# frozen_string_literal: true

require_relative 'event_action'
require_relative '../../constants/dict_constants'

module SpeckleConnector
  module Actions
    module Events
      # Event actions related to entities.
      class EntityEventAction < EventAction
        # Event action when entity modified/changed.
        # PS: this handler action only triggers for edges and it's vertices since we attach EntityObserver to
        # only edge and vertex entities. This is a limitation of the Sketchup API that can't handles edges with
        # EntitiesObserver.
        class OnChangeEntity
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            edges = []
            event_data.each do |event_d|
              event_d.each do |d|
                next if d.deleted?

                edges.append(d) if d.is_a?(Sketchup::Edge)
                edges += d.edges if d.is_a?(Sketchup::Vertex) && d.edges
              end
            end
            edges.uniq!
            edge_ids = edges.collect(&:persistent_id)
            new_speckle_state = state.speckle_state.with_changed_entity_persistent_ids(edge_ids)
            state.with_speckle_state(new_speckle_state)
          end
        end

        # Handlers that are used to handle specific events
        ACTIONS = {
          onChangeEntity: OnChangeEntity
        }.freeze

        def self.actions
          ACTIONS
        end
      end
    end
  end
end
