# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle mesh entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleMeshEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      def initialize(sketchup_face, traversed_speckle_object)
        @speckle_children_objects = traversed_speckle_object[:__closure].keys
        super(sketchup_face, traversed_speckle_object, speckle_children_objects)
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
