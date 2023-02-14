# frozen_string_literal: true

require_relative 'event_action'
require_relative '../../sketchup_model/utils/face_utils'

module SpeckleConnector
  module Actions
    module Events
      class EntitiesEventAction < EventAction
        class OnElementAdded
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            # TODO: Do state updates when element added
            state
          end
        end

        class OnElementModified
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            speckle_state = state.speckle_state
            modified_entity = event_data[0][1]
            if modified_entity.is_a?(Sketchup::Face)
              path = state.sketchup_state.sketchup_model.active_path
              modified_faces = SketchupModel::Utils::FaceUtils.near_faces(modified_entity.edges)
              parent_ids = path.nil? ? [] : path.collect(&:persistent_id)
              ids_to_invalidate = modified_faces.collect(&:persistent_id) + parent_ids
              entities_to_invalidate = speckle_entities_to_invalidate(speckle_state, ids_to_invalidate)
              new_speckle_state = invalidate_speckle_entities(speckle_state, entities_to_invalidate)
              return state.with_speckle_state(new_speckle_state)
            end

            state
          end

          # @param speckle_state [States::SpeckleState] the current state of the Speckle
          def self.speckle_entities_to_invalidate(speckle_state, ids)
            speckle_state.speckle_entities.to_h.select { |id, _| ids.include?(id) }
          end

          # @param speckle_state [States::SpeckleState] the current state of the Speckle
          def self.invalidate_speckle_entities(speckle_state, entities_to_invalidate)
            speckle_entities = speckle_state.speckle_entities
            entities_to_invalidate.each do |id, speckle_entity|
              edited_speckle_entity = speckle_entity.with_edited
              speckle_entities = speckle_entities.put(id, edited_speckle_entity)
            end
            speckle_state.with_speckle_entities(speckle_entities)
          end
        end

        class OnElementRemoved
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            # TODO: Do state updates when element removed
            state
          end
        end

        # Handlers that are used to handle specific events
        ACTIONS = {
          onElementRemoved: OnElementRemoved,
          onElementAdded: OnElementAdded,
          onElementModified: OnElementModified
        }.freeze

        def self.actions
          ACTIONS
        end
      end
    end
  end
end
