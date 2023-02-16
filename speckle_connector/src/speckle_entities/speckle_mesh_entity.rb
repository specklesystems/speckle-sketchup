# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle mesh entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleMeshEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      # @return [Hash{String=>SpeckleObjects::Base}] speckle objects belongs to edge
      attr_reader :children

      def initialize(sketchup_face, traversed_speckle_object, stream_id)
        @children = traversed_speckle_object[:__closure].nil? ? {} : traversed_speckle_object[:__closure]
        super(sketchup_face, traversed_speckle_object, children, stream_id)
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
