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

      # @return [SpeckleObjects::Base] Speckle object that represented on server.
      attr_reader :speckle_object

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

      attr_reader :source_material

      # @param sketchup_entity [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      def initialize(sketchup_entity, traversed_speckle_object, children, stream_id)
        @status = SpeckleEntityStatus::UP_TO_DATE
        @source_material = sketchup_entity.material
        @valid_stream_ids = [stream_id]
        @invalid_stream_ids = []
        @sketchup_entity = sketchup_entity
        @application_id = @sketchup_entity.persistent_id
        @id = traversed_speckle_object[:id]
        @total_children_count = traversed_speckle_object[:totalChildrenCount]
        @speckle_object = traversed_speckle_object
        @speckle_type = speckle_object[:speckle_type]
        @speckle_children_objects = children
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler
          .write_initial_base_data(@sketchup_entity, application_id, id, speckle_type,
                                   @speckle_children_objects.length, stream_id)

        # FIXME: Understand why below condition does not match for same cases. I guess it is a typo bug.
        # unless total_children_count == speckle_children_objects.length
        #   raise StandardError "total children count mismatch for #{application_id}"
        # end
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
    end
  end
end
