# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative 'speckle_line_entity'
require_relative 'speckle_mesh_entity'
require_relative 'speckle_block_instance_entity'

module SpeckleConnector
  # Speckle entities are the state holder objects to achieve diffing, caching and updating.
  # They are created whenever user send/receive objects between SketchUp and Speckle XYZ server.
  # When Sketchup Entity is sent, by checking objects attributes, allow us to understand this object is sent previously?
  #   If yes, then use it for caching purpose only if object hasn't changed since it's previous sent state.
  #   If object has sent before but changed after, then update the SpeckleEntity with new traversed object.
  #   If no, then create SpeckleEntity and add it to the SpeckleState to check later.
  module SpeckleEntities
    # Speckle entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    def self.with_converted(skp_entity, traversed_objs)
      # return the same object if it is already SpeckleEntity
      return skp_entity if skp_entity.is_a?(SpeckleEntity)
      return SpeckleBlockInstanceEntity.new(skp_entity, traversed_objs) if skp_entity.is_a?(Sketchup::Group)
      return SpeckleBlockInstanceEntity.new(skp_entity, traversed_objs) if skp_entity.is_a?(Sketchup::ComponentInstance)
      return SpeckleMeshEntity.new(skp_entity, traversed_objs) if skp_entity.is_a?(Sketchup::Face)

      SpeckleLineEntity.new(skp_entity, traversed_objs) if skp_entity.is_a?(Sketchup::Edge)
    end
  end
end
