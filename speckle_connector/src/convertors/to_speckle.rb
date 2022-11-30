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
      # @return [Hash{Symbol=>Object}] layers to hold it's objects under the base object.
      attr_reader :layers

      def initialize(sketchup_model)
        super(sketchup_model)
        @layers = add_all_layers
      end

      def convert_selection
        sketchup_model.selection.each do |entity|
          converted_object = convert(entity)
          layer_name = entity_layer_name(entity)
          layers[layer_name].push(converted_object)
        end
        layers
      end

      # @param entity [Sketchup::Entity] sketchup entity to convert Speckle.
      def convert(entity)
        return SpeckleObjects::Geometry::Line.from_edge(entity, @units).to_h if entity.is_a?(Sketchup::Edge)
        return SpeckleObjects::Geometry::Mesh.from_face(entity, @units) if entity.is_a?(Sketchup::Face)
        if entity.is_a?(Sketchup::Group)
          return SpeckleObjects::Other::BlockInstance.from_group(entity, @units, @definitions)
        end
        if entity.is_a?(Sketchup::ComponentInstance)
          return SpeckleObjects::Other::BlockInstance.from_component_instance(entity, @units, @definitions)
        end

        SpeckleObjects::Other::BlockDefinition.from_definition(entity, @units, @definitions)
      end

      def add_all_layers
        layer_objects = add_layers(sketchup_model.layers.layers)
        add_layers_from_folders(sketchup_model.layers.folders, layer_objects)
        layer_objects
      end

      # @param layers [Array<Sketchup::Layer>] layers in sketchup model
      def add_layers(layers, layer_objects = {}, parent_name = '')
        layers.each do |layer|
          layer_name = parent_name.empty? ? "@#{layer.display_name}" : "#{parent_name}::#{layer.display_name}"
          layer_objects[layer_name] = []
        end
        layer_objects
      end

      # @param folders [Array<Sketchup::LayerFolder>] layer folders in sketchup model
      def add_layers_from_folders(folders, layer_objects, parent_name = '')
        folders.each do |folder|
          folder_name = parent_name.empty? ? "@#{folder.display_name}" : "#{parent_name}::#{folder.display_name}"
          add_layers(folder.layers, layer_objects, folder_name)
          add_layers_from_folders(folder.folders, layer_objects, folder_name) unless folder.folders.empty?
        end
      end

      # @param entity [Sketchup::Entity] entity to find root layer
      def entity_layer_name(entity)
        layer_name = entity.layer.name
        if entity.layer.folder.nil?
          "@#{layer_name}"
        else
          folders = folder_name(entity.layer.folder)
          path = ''
          folders.reverse.each do |folder|
            path += "#{folder}::"
          end
          "@#{path}#{layer_name}"
        end
      end

      def folder_name(folder, folders = [])
        if folder.folder.nil?
          folders.push(folder.display_name)
        else
          folder_name(folder.folder, folders.push(folder.display_name))
        end
      end
    end
  end
end
