# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle mesh entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleMeshEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      def initialize(sketchup_face, traversed_speckle_objects, parent)
        children, speckle_object = traversed_speckle_objects.partition { |obj| obj[1][:speckle_type] == 'Speckle.Core.Models.DataChunk' }
        super(sketchup_face, speckle_object[0][1], children, parent)
        @speckle_children_objects = children.to_h
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
