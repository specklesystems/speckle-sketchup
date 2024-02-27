# frozen_string_literal: true

require_relative 'speckle_entity_status'
require_relative '../immutable/immutable'
require_relative '../convertors/units'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module SpeckleEntities
    # Speckle base entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleEntity
      include Immutable::ImmutableUtils
      # @return [Sketchup::Entity] Sketchup Entity represents {SpeckleEntity} on the model.
      attr_reader :sketchup_entity

      # @return [String] Speckle object type.
      attr_reader :speckle_type

      # @return [Integer] application id of the Sketchup Entity.
      attr_reader :application_id

      # @return [String] id of the Speckle Base Object
      attr_reader :id

      # @return [Integer] total children count of the Speckle Base Object
      attr_reader :total_children_count

      # @return [Hash{String=>SpeckleObjects::Base}] Speckle objects belongs to edge
      attr_reader :speckle_children_objects

      # @return [Array<String>] speckle entity that valid on streams
      attr_reader :valid_stream_ids

      # @return [Array<String>] speckle entity that invalid on streams
      attr_reader :invalid_stream_ids

      # @return [SpeckleEntityStatus] current status of the Speckle Entity.
      attr_reader :status

      attr_reader :source_material, :active_diffing_stream_id

      # @param sketchup_entity [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      # rubocop:disable Metrics/ParameterLists
      def initialize(sketchup_entity, speckle_id, application_id, speckle_type, children, valid_stream_ids,
                     invalid_stream_ids = [])
        @status = SpeckleEntityStatus::UP_TO_DATE
        @source_material = sketchup_entity.material
        @active_diffing_stream_id = nil
        @valid_stream_ids = valid_stream_ids
        @invalid_stream_ids = invalid_stream_ids
        @sketchup_entity = sketchup_entity
        @application_id = application_id
        @id = speckle_id
        @total_children_count = children.nil? ? 0 : children.length
        @speckle_type = speckle_type
        @speckle_children_objects = children.nil? ? [] : children
      end
      # rubocop:enable Metrics/ParameterLists

      def write_initial_base_data
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler
          .write_initial_base_data(@sketchup_entity, application_id, id, speckle_type,
                                   @speckle_children_objects, valid_stream_ids.first)
      end

      def with_up_to_date
        with(:@status => SpeckleEntityStatus::UP_TO_DATE)
      end

      def with_invalid
        valid = valid_stream_ids
        sketchup_entity.set_attribute(SPECKLE_BASE_OBJECT, VALID_STREAM_IDS, [])
        sketchup_entity.set_attribute(SPECKLE_BASE_OBJECT, INVALID_STREAM_IDS, valid)
        with(:@valid_stream_ids => [], :@invalid_stream_ids => valid)
      end

      def activate_diffing(stream_id, material)
        sketchup_entity.material = material
        with(:@active_diffing_stream_id => stream_id)
      end

      def deactivate_diffing
        sketchup_entity.material = @source_material
        with(:@active_diffing_stream_id => nil)
      end

      def change_material(material)
        sketchup_entity.material = material
      end

      def revert_material
        sketchup_entity.material = source_material
      end

      def with_valid_stream_id(stream_id)
        return self if valid_stream_ids.include?(stream_id)

        invalid_ids = @invalid_stream_ids.include?(stream_id) ? @invalid_stream_ids - [stream_id] : @invalid_stream_ids
        valid_ids = valid_stream_ids + [stream_id]
        sketchup_entity.set_attribute(SPECKLE_BASE_OBJECT, VALID_STREAM_IDS, valid_ids)
        sketchup_entity.set_attribute(SPECKLE_BASE_OBJECT, INVALID_STREAM_IDS, invalid_ids)

        # if sketchup_entity.is_a?(Sketchup::Group) || sketchup_entity.is_a?(Sketchup::ComponentInstance)
        #   sketchup_entity.definition.set_attribute(SPECKLE_BASE_OBJECT, VALID_STREAM_IDS, valid_ids)
        #   sketchup_entity.definition.set_attribute(SPECKLE_BASE_OBJECT, INVALID_STREAM_IDS, invalid_ids)
        # end

        with(:@valid_stream_ids => @valid_stream_ids + [stream_id], :@invalid_stream_ids => invalid_ids)
      end

      def with_edited
        with(:@status => SpeckleEntityStatus::EDITED)
      end

      def with_removed
        with(:@status => SpeckleEntityStatus::REMOVED)
      end

      def valid?
        sketchup_entity.valid?
      end

      # @param state [States::State] state of the application
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def self.from_speckle_object(state, speckle_object, entities, stream_id)
        return state, [] if entities.empty?

        speckle_id = speckle_object['id']
        application_id = speckle_object['applicationId']
        speckle_type = speckle_object['speckle_type']
        children = speckle_object['__closure'].nil? ? [] : speckle_object['__closure']
        speckle_state = state.speckle_state
        entities.each do |entity|
          next if entity.is_a?(Sketchup::Material) || entity.is_a?(Sketchup::Page)
          next if (entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)) &&
                  !state.user_state.user_preferences[:register_speckle_entity]

          if entity.is_a?(Sketchup::ComponentDefinition)
            definition = speckle_object['definition'] || speckle_object['@block_definition'] ||
              speckle_object['block_definition']
            if definition
              speckle_id = definition['id']
              speckle_type = definition['speckle_type']
            end
          end

          ent = SpeckleEntity.new(entity, speckle_id, application_id, speckle_type, children, [stream_id])
          ent.write_initial_base_data
          speckle_state = speckle_state.with_speckle_entity(ent)
        end
        new_state = state.with_speckle_state(speckle_state)
        return new_state, entities
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
