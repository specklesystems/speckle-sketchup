# frozen_string_literal: true

require_relative '../speckle_entities/speckle_line_entity'
require_relative '../speckle_entities/speckle_base_entity'

module SpeckleConnector
  module SpeckleEntities
    # Speckle entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    module SpeckleEntity
      def self.with_converted(skp_entity, traversed_object)
        # return the same object if it is already SpeckleEntity
        return skp_entity if skp_entity.is_a?(SpeckleEntity::SpeckleBaseEntity)
        # return SpeckleBlockEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::Group)
        # return SpeckleBlockEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::ComponentInstance)
        # return SpeckleMeshEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::Face)

        SpeckleLineEntity.new(skp_entity, traversed_object) if skp_entity.is_a?(Sketchup::Edge)
      end
    end
  end
end
