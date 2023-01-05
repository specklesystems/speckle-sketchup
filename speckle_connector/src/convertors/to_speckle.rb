# frozen_string_literal: true

require_relative 'converter'
require_relative 'base_object_serializer'
require_relative '../speckle_objects/base'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/mesh'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/block_definition'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToSpeckle < Converter
      # @return [Hash{Symbol=>Array}] layers to hold it's objects under the base object.
      attr_reader :layers

      def initialize(sketchup_model)
        super(sketchup_model)
        @layers = add_all_layers
      end

      # Convert selected objects by putting them into related array that grouped by layer.
      # @return [Hash{Symbol=>Array}] layers -which only have objects- to hold it's objects under the base object.
      def convert_selection_to_base(preferences)
        sketchup_model.selection.each do |entity|
          converted_object = convert(entity, preferences)
          layer_name = entity_layer_path(entity)
          layers[layer_name].push(converted_object)
        end
        # send only layers that have any object
        base_object_properties = layers.reject { |_layer_name, objects| objects.empty? }
        SpeckleObjects::Base.with_detached_layers(base_object_properties)
      end

      # Serialized and traversed information to send batches.
      # @param base [SpeckleObjects::Base] base object to serialize.
      # @return [String, Integer, Array<Object>] base id, total_children_count of base and batches
      def send_info(base)
        serializer = SpeckleConnector::Converters::BaseObjectSerializer.new
        # t = Time.now.to_f
        id, _traversed = serializer.serialize(base)
        # puts "Generating traversed object elapsed #{Time.now.to_f - t} s"
        base_total_children_count = serializer.total_children_count(id)
        return id, base_total_children_count, serializer.batch_objects
      end

      # @param entity [Sketchup::Entity] sketchup entity to convert Speckle.
      def convert(entity, preferences)
        convert = method(:convert)
        return SpeckleObjects::Geometry::Line.from_edge(entity, @units).to_h if entity.is_a?(Sketchup::Edge)
        return SpeckleObjects::Geometry::Mesh.from_face(entity, @units) if entity.is_a?(Sketchup::Face)
        if entity.is_a?(Sketchup::Group)
          return SpeckleObjects::Other::BlockInstance.from_group(entity, @units, @definitions, preferences, &convert)
        end
        if entity.is_a?(Sketchup::ComponentInstance)
          return SpeckleObjects::Other::BlockInstance.from_component_instance(entity, @units, @definitions, preferences, &convert)
        end
        if entity.is_a?(Sketchup::ComponentDefinition)
          return SpeckleObjects::Other::BlockDefinition.from_definition(entity, @units, @definitions, preferences, &convert)
        end

        nil
      end

      # Create layers -> {Hash{Symbol=>Array}} from sketchup model with empty array as hash entry values.
      # This method add first headless layers (not belong to any folder),
      # then goes through each folder, their sub-folders and their layers.
      # @return [Hash{Symbol=>Array}] layers from sketchup model with empty array as hash entry values.
      def add_all_layers
        # add headless layers
        layer_objects = add_layers(sketchup_model.layers.layers)
        # add layers from folders
        add_layers_from_folders(sketchup_model.layers.folders, layer_objects)
        layer_objects
      end

      # @param layers [Array<Sketchup::Layer>] layers in sketchup model
      # @return [Hash{Symbol=>Array}] layers with empty array value.
      def add_layers(layers, layer_objects = {}, parent_name = '')
        layers.each do |layer|
          layer_name = parent_name.empty? ? "@#{layer.display_name}" : "#{parent_name}::#{layer.display_name}"
          layer_objects[layer_name] = []
        end
        layer_objects
      end

      # @param folders [Array<Sketchup::LayerFolder>] layer folders in sketchup model.
      # @param layer_objects [Hash{Symbol=>Array}] layer objects to fill in.
      # @param parent_name [String] parent folder name to structure layer path before send to Speckle.
      #  ex: "@#{parent_name}::#{layer_name}"
      def add_layers_from_folders(folders, layer_objects, parent_name = '')
        folders.each do |folder|
          folder_name = parent_name.empty? ? "@#{folder.display_name}" : "#{parent_name}::#{folder.display_name}"
          add_layers(folder.layers, layer_objects, folder_name)
          add_layers_from_folders(folder.folders, layer_objects, folder_name) unless folder.folders.empty?
        end
      end

      # Find layer path of given Sketchup entity.
      # @param entity [Sketchup::Entity] entity to find root layer.
      # @return [String] layer path of Sketchup entity.
      def entity_layer_path(entity)
        layer_name = entity.layer.display_name
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

      # Nested method to retrieve sub-folders until nothing found.
      # @return [Array<String>] folder names as list from bottom to top. Might need to be reversed if you want to see
      #  from top to bottom.
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
