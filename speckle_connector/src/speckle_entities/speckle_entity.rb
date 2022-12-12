# frozen_string_literal: true

require_relative '../speckle_entities/speckle_line_entity'

module SpeckleConnector
  module SpeckleEntities
    # Speckle entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    module SpeckleEntity
      def self.with_converted(skp_model, skp_entity)
        # return the same object if it is already SpeckleEntity
        return skp_entity if skp_entity.is_a?(SpeckleEntity)
        return SpeckleBlockEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::Group)
        return SpeckleBlockEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::ComponentInstance)
        return SpeckleMeshEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::Face)

        SpeckleLineEntity.new(skp_model, skp_entity) if skp_entity.is_a?(Sketchup::Edge)
      end
    end
  end
end
