# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../convertors/units'
require_relative '../speckle_objects/base'
require_relative '../speckle_entities/speckle_line_entity'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module SpeckleEntities
    # Speckle base entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleBaseEntity
      include Immutable::ImmutableUtils
      # @return [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      attr_reader :sketchup_entity

      # @return [SpeckleObjects::Base] speckle object that represented on server.
      attr_reader :speckle_object

      # @return [Integer] application id of the sketchup entity.
      attr_reader :application_id

      # @param sketchup_entity [Sketchup::Entity] sketchup entity represents {SpeckleEntity} on the model.
      def initialize(sketchup_model, sketchup_entity)
        @sketchup_entity = sketchup_entity
        @application_id = @sketchup_entity.persistent_id
        @speckle_object = SpeckleObjects::Base.new
        su_unit = sketchup_model.options['UnitsOptions']['LengthUnit']
        @units =  Converters::SKETCHUP_UNITS[su_unit]
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.write_initial_base_data(@sketchup_entity)
      end

      def valid?
        sketchup_entity.valid?
      end
    end
  end
end
