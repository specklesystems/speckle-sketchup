# frozen_string_literal: true

require_relative 'speckle_entity'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleEntities
    # Speckle block instance entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleBlockInstanceEntity < SpeckleEntities::SpeckleEntity
      include Immutable::ImmutableUtils

      # @return [Hash{String=>SpeckleObjects::Base}] speckle objects belongs to block instance
      attr_reader :speckle_children_objects

      # @return [Boolean] whether block instance represented as sketchup group or component instance
      attr_reader :is_sketchup_group

      def initialize(sketchup_group_or_component_instance, traversed_speckle_objects)
        speckle_object, children = traversed_speckle_objects.partition do |obj|
          obj[1][:speckle_type] == 'Objects.Other.BlockInstance'
        end
        super(sketchup_group_or_component_instance, speckle_object[0][1], children)
        @speckle_children_objects = children
        @is_sketchup_group = speckle_object[0][1][:is_sketchup_group]
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
