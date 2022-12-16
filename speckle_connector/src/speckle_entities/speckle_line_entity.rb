# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle line entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleLineEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      # @return [Hash{String=>SpeckleObjects::Base}] speckle objects belongs to edge
      attr_reader :speckle_children_objects

      def initialize(sketchup_edge, traversed_speckle_objects, parent)
        children, speckle_object = traversed_speckle_objects.partition { |obj| obj[1][:speckle_type] == 'Speckle.Core.Models.DataChunk' }
        super(sketchup_edge, speckle_object[0][1], children, parent)
        @speckle_children_objects = children
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
