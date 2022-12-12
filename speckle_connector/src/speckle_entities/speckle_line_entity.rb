# frozen_string_literal: true

require_relative 'speckle_base_entity'
require_relative '../immutable/immutable'
require_relative '../speckle_objects/geometry/line'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module SpeckleEntities
    # Speckle line entity is the state object for Sketchup::Entity and it's converted (or not yet) state.
    class SpeckleLineEntity < SpeckleBaseEntity
      include Immutable::ImmutableUtils

      # @return [SpeckleObjects::Geometry::Line] speckle line object
      attr_reader :speckle_object

      def initialize(sketchup_model, sketchup_edge)
        super(sketchup_model, sketchup_edge)
        @speckle_object = SpeckleObjects::Geometry::Line.from_edge(sketchup_edge, units)
      end

      alias sketchup_edge sketchup_entity
    end
  end
end
