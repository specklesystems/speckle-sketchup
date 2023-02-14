# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle line entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleLineEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      # @return [Hash{String=>SpeckleObjects::Base}] speckle objects belongs to edge
      attr_reader :children

      def initialize(sketchup_edge, traversed_speckle_object)
        @children = traversed_speckle_object[:__closure].nil? ? {} : traversed_speckle_object[:__closure]
        super(sketchup_edge, traversed_speckle_object, children)
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
