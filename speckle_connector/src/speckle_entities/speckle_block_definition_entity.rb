# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle block definition entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleBlockDefinitionEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      # @return [Hash{String=>SpeckleObjects::Base}] speckle objects belongs to block instance
      attr_reader :children

      def initialize(sketchup_group_or_component_instance, traversed_speckle_object)
        @children = traversed_speckle_object[:__closure].nil? ? {} : traversed_speckle_object[:__closure]
        super(sketchup_group_or_component_instance, traversed_speckle_object, children)
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
