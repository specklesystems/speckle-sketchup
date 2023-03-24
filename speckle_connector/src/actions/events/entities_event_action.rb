# frozen_string_literal: true

require_relative 'event_action'
require_relative '../../sketchup_model/utils/face_utils'
require_relative '../../constants/dict_constants'

module SpeckleConnector
  module Actions
    module Events
      # Event actions related to entities.
      class EntitiesEventAction < EventAction
        # Event action when element added.
        class OnElementAdded
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            modified_entities = event_data.to_a.collect { |e| e[1] }
            # do not copy speckle base object specific attributes, because they are entity specific
            modified_entities.each { |entity| entity.delete_attribute(SPECKLE_BASE_OBJECT) }
            state
          end
        end

        # Event action when element modified.
        class OnElementModified
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            speckle_state = state.speckle_state
            modified_entity = event_data[0][1]
            if modified_entity.is_a?(Sketchup::Face)
              path = state.sketchup_state.sketchup_model.active_path
              modified_faces = SketchupModel::Utils::FaceUtils.near_faces(modified_entity.edges)
              path_objects = path.nil? ? [] : path + path.collect(&:definition)
              parent_ids = path_objects.collect(&:persistent_id)
              ids_to_invalidate = modified_faces.collect(&:persistent_id) + parent_ids
              entities_to_invalidate = speckle_entities_to_invalidate(speckle_state, ids_to_invalidate)
              new_speckle_state = invalidate_speckle_entities(speckle_state, entities_to_invalidate)
              # This is the place we can send information to UI for diffing check
              diffing = state.user_state.preferences[:user][:diffing]
              new_speckle_state = new_speckle_state.with_invalid_streams_queue if diffing
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
              edited_speckle_entity = speckle_entity.with_invalid
              speckle_entities = speckle_entities.put(id, edited_speckle_entity)
            end
            speckle_state.with_speckle_entities(speckle_entities)
          end
        end

        # Event action when element removed.
        class OnElementRemoved
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, _event_data)
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
