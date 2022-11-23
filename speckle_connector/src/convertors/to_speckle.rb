# frozen_string_literal: true

require_relative 'converter'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/mesh'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/block_definition'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToSpeckle < Converter
      def convert_selection
        sketchup_model.selection.map { |entity| convert(entity) }
      end

      def convert(obj)
        return SpeckleObjects::Geometry::Line.from_edge(obj, @units).to_h if obj.is_a?(Sketchup::Edge)
        return SpeckleObjects::Geometry::Mesh.from_face(obj, @units) if obj.is_a?(Sketchup::Face)
        return SpeckleObjects::Other::BlockInstance.from_group(obj, @units, @definitions) if obj.is_a?(Sketchup::Group)
        if obj.is_a?(Sketchup::ComponentInstance)
          return SpeckleObjects::Other::BlockInstance.from_component_instance(obj, @units, @definitions)
        end

        SpeckleObjects::Other::BlockDefinition.from_definition(obj, @units, @definitions)
      end
    end
  end
end
