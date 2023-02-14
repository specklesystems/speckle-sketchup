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

      # @return [SpeckleEntityStatus] current status of the Speckle Entity.
      attr_reader :status

      # @param sketchup_entity [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      def initialize(sketchup_entity, traversed_speckle_object, children)
        @status = SpeckleEntityStatus::UP_TO_DATE
        @sketchup_entity = sketchup_entity
        @application_id = @sketchup_entity.persistent_id
        @id = traversed_speckle_object[:id]
        @total_children_count = traversed_speckle_object[:totalChildrenCount]
        @speckle_object = traversed_speckle_object
        @speckle_type = speckle_object[:speckle_type]
        @speckle_children_objects = children
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler
          .write_initial_base_data(@sketchup_entity, application_id, id, speckle_type,
                                   @speckle_children_objects.length)

        # FIXME: Understand why below condition does not match for same cases. I guess it is a typo bug.
        # unless total_children_count == speckle_children_objects.length
        #   raise StandardError "total children count mismatch for #{application_id}"
        # end
      end

      def with_up_to_date
        with(:@status => SpeckleEntityStatus::UP_TO_DATE)
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
