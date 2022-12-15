# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../convertors/units'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module SpeckleEntities
    # Speckle base entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleEntity
      include Immutable::ImmutableUtils
      # @return [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      attr_reader :sketchup_entity

      # @return [SpeckleObjects::Base] speckle object that represented on server.
      attr_reader :speckle_object

      # @return [String] speckle object type.
      attr_reader :speckle_type

      # @return [Integer] application id of the sketchup entity.
      attr_reader :application_id

      # @return [String] id of the Speckle Base Object
      attr_reader :id

      # @return [Integer] total children count of the Speckle Base Object
      attr_reader :total_children_count

      # @return [Hash{String=>SpeckleObjects::Base}] speckle objects belongs to edge
      attr_reader :speckle_children_objects

      # @param sketchup_entity [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      def initialize(sketchup_entity, traversed_speckle_object, children)
        @sketchup_entity = sketchup_entity
        @application_id = @sketchup_entity.persistent_id
        @id = traversed_speckle_object[:id]
        @total_children_count = traversed_speckle_object[:totalChildrenCount]
        @speckle_object = traversed_speckle_object
        @speckle_type = speckle_object[:speckle_type]
        @speckle_children_objects = children.to_h
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler
          .write_initial_base_data(@sketchup_entity, id, speckle_type, @speckle_children_objects.keys.to_a)

        unless total_children_count == speckle_children_objects.length
          raise StandardError "total children count mismatch for #{application_id}"
        end
      end

      def valid?
        sketchup_entity.valid?
      end
    end
  end
end
