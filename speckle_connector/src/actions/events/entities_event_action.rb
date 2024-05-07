# frozen_string_literal: true

require_relative 'event_action'
require_relative '../../actions/send_actions/send_card_expiration_check'
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

            wrapped_entity_ids = wrapped_entity_ids(modified_entities)
            state = EntitiesEventAction.run_expiration_checks(state, wrapped_entity_ids) if wrapped_entity_ids.any?

            attach_edge_entity_observer(modified_entities.grep(Sketchup::Edge), state.speckle_state.observers[ENTITY_OBSERVER])
            state
          end

          def self.wrapped_entity_ids(modified_entities)
            wrapped_entity_ids = []
            modified_entities.select { |e| e.respond_to?(:definition) }.each do |c|
              wrapped_entity_ids += c.definition.entities.collect(&:persistent_id)
            end
            wrapped_entity_ids
          end

          # It is needed for attaching EntityObserver to newly added edges to track them with a hacky way.
          # This hacky way is because of limitation on Sketchup API that observer cannot catch changes on Edges
          # with EntitiesObserver.
          def self.attach_edge_entity_observer(edges, observer)
            edges.each do |edge|
              edge.add_observer(observer)
              edge.start.add_observer(observer)
              edge.end.add_observer(observer)
            end
          end
        end

        # Event action when element modified.
        class OnElementModified
          # @param state [States::State] the current state of the SpeckleConnector Application
          def self.update_state(state, event_data)
            # modified_entity = event_data[0][1]
            modified_entities = event_data.collect { |data| data[1] }.to_a
            # near_faces = get_near_faces(modified_entities)
            definition_faces = get_definition_faces(modified_entities)
            modified_entity_ids = modified_entities.collect(&:persistent_id) + definition_faces.collect(&:persistent_id)
            parent_ids = parent_ids(state.sketchup_state.sketchup_model)
            modified_entity_ids += parent_ids
            state = EntitiesEventAction.run_expiration_checks(state, modified_entity_ids)
            # if modified_entity.is_a?(Sketchup::Face)
            #   path = state.sketchup_state.sketchup_model.active_path
            #   modified_faces = SketchupModel::Utils::FaceUtils.near_faces(modified_entity.edges)
            #   path_objects = path.nil? ? [] : path + path.collect(&:definition)
            #   parent_ids = path_objects.collect(&:persistent_id)
            #   ids_to_invalidate = modified_faces.collect(&:persistent_id) + parent_ids
            #   entities_to_invalidate = speckle_entities_to_invalidate(speckle_state, ids_to_invalidate)
            #   new_speckle_state = invalidate_speckle_entities(speckle_state, entities_to_invalidate)
            #   # This is the place we can send information to UI for diffing check
            #   diffing = state.user_state.preferences[:user][:diffing]
            #   new_speckle_state = new_speckle_state.with_invalid_streams_queue if diffing
            #   return state.with_speckle_state(new_speckle_state)
            # end

            state
          end

          def self.get_near_faces(modified_entities)
            near_faces = []
            modified_entities.each do |modified_entity|
              next unless modified_entity.is_a?(Sketchup::Face)

              near_faces += SketchupModel::Utils::FaceUtils.near_faces(modified_entity.edges)
            end
            near_faces
          end

          def self.get_definition_faces(modified_entities)
            definition_faces = []
            modified_entities.each do |modified_entity|
              next unless modified_entity.is_a?(Sketchup::Face)
              next unless modified_entity.parent.is_a?(Sketchup::ComponentDefinition)

              definition_faces += modified_entity.parent.entities.grep(Sketchup::Face)
            end
            definition_faces
          end

          def self.parent_ids(sketchup_model)
            path = sketchup_model.active_path
            path_objects = path.nil? ? [] : path + path.collect(&:definition)
            path_objects.collect(&:persistent_id)
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

        # @param state [States::State] the current state of the SpeckleConnector Application
        # @param changed_entity_ids [Array<Integer> | Array<String>] list of changed entity ids
        def self.run_expiration_checks(state, changed_entity_ids)
          new_speckle_state = state.speckle_state.with_changed_object_ids(changed_entity_ids)
          state = state.with_speckle_state(new_speckle_state)
          Actions::SendCardExpirationCheck.update_state(state)
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
