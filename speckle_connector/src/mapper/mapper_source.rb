# frozen_string_literal: true

require_relative '../speckle_objects/built_elements/level'
require_relative '../speckle_objects/built_elements/revit/revit_element_type'

module SpeckleConnector
  # Mapper is a tool to convert SketchUp entities to other applications' native objects.
  module Mapper
    # Mapper source object that collects information about stream id and commit id to identify source in the branch,
    # also contains levels and family types to be able to map objects with them.
    class MapperSource
      # @return [String] stream id of the mapper source.
      attr_reader :stream_id

      # @return [String] commit id of the mapper source.
      attr_reader :commit_id

      # @return [Array<SpeckleObjects::BuiltElements::Level>] levels in the source branch.
      attr_reader :levels

      # @return [Hash{String=>Array<SpeckleObjects::BuiltElements::Revit::RevitElementType>}] revit element types.
      attr_reader :types

      def initialize(stream_id, commit_id, levels, types)
        @stream_id = stream_id
        @commit_id = commit_id
        @levels = levels
        @types = types
      end
    end
  end
end
