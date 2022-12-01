# frozen_string_literal: true

require_relative 'converter'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/mesh'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToNative < Converter
      # Module aliases
      GEOMETRY = SpeckleObjects::Geometry
      OTHER = SpeckleObjects::Other

      # Class aliases
      POINT = GEOMETRY::Point
      LINE = GEOMETRY::Line
      MESH = GEOMETRY::Mesh
      BLOCK_DEFINITION = OTHER::BlockDefinition
      BLOCK_INSTANCE = OTHER::BlockInstance

      BASE_OBJECT_PROPS = %w[applicationId id speckle_type totalChildrenCount].freeze
      CONVERTABLE_SPECKLE_TYPES = %w[
        Objects.Geometry.Line
        Objects.Geometry.Polyline
        Objects.Geometry.Mesh
        Objects.Geometry.Brep
        Objects.Other.BlockInstance
        Objects.Other.BlockDefinition
        Objects.Other.RenderMaterial
      ].freeze

      def can_convert_to_native(obj)
        return false unless obj.is_a?(Hash) && obj.key?('speckle_type')

        CONVERTABLE_SPECKLE_TYPES.include?(obj['speckle_type'])
      end

      def ignored_speckle_type?(obj)
        ['Objects.BuiltElements.Revit.Parameter'].include?(obj['speckle_type'])
      end

      def receive_commit_object(obj, stream_name, branch_name, branch_id)
        create_layers(obj.keys.filter_map { |key| key if key.start_with?('@') }, sketchup_model.layers)
        default_commit_layer = sketchup_model.layers.layers.find { |layer| layer.display_name == '@Untagged' }
        traverse_commit_object(obj, sketchup_model.layers, default_commit_layer)
      end

      def create_layers(layers, folder)
        layers_with_folders = layers.map { |layer| layer[1..-1] }
        folder_layers, headless_layers = layers_with_folders.partition { |layer| layer.include?('::') }
        folder_arrays = create_folder_arrays(folder_layers)
        create_headless_layers(headless_layers, folder)
        create_folder_layers(folder_arrays, folder)
      end

      # @param folder [Sketchup::LayerFolder] layer folder to create commit layers under it.
      def create_headless_layers(headless_layers, folder)
        headless_layers.each do |layer_name|
          # layer_name = "@#{layer_name}" if layer_name == 'Untagged'
          layer = sketchup_model.layers.add(layer_name)
          folder.add_layer(layer) unless folder.layers.any? { |layer| layer.display_name == layer_name }
        end
      end

      def create_folder_arrays(folder_layers)
        folder_layers.collect { |folder_layer| folder_layer.split('::') }
      end

      def create_folder_layer(folder_array, folder)
        if folder_array.length > 1
          # add folder if it is not exist.
          folder.add_folder(folder_array[0]) unless folder.folders.any? { |f| f.display_name == folder_array[0] }
          new_folder = folder.folders.find { |f| f.display_name == folder_array[0] }
          create_folder_layer(folder_array[1..-1], new_folder)
        else
          layer = sketchup_model.layers.add(folder_array[0])
          folder.add_layer(layer) unless folder.layers.any? { |layer| layer.display_name == layer }
        end
      end

      # @param folder [Sketchup::LayerFolder] layer folder to create commit layers under it.
      def create_folder_layers(folder_arrays, folder)
        folder_arrays.each do |folder_array|
          create_folder_layer(folder_array, folder)
        end
      end

      # Traversal method to create Sketchup objects from upcoming base object.
      # @param obj [Hash, Array] object might be source base object or it's sub objects, because this method is a
      #   self-caller method means that call itself according to conditions inside of it.
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def traverse_commit_object(obj, commit_folder, layer)
        if can_convert_to_native(obj)
          convert_to_native(obj, layer)
        elsif obj.is_a?(Hash) && obj.key?('speckle_type')
          return if ignored_speckle_type?(obj)

          if obj['displayValue'].nil?
            puts(">>> Found #{obj['speckle_type']}: #{obj['id']}. Continuing traversal.")
            props = obj.keys.filter_map { |key| key unless key.start_with?('_') }
            props.each do |prop|
              layer_path = prop if prop.start_with?('@') && obj[prop].is_a?(Array)
              layer = find_layer(layer_path, commit_folder, layer)
              traverse_commit_object(obj[prop], commit_folder, layer)
            end
          else
            puts(">>> Found #{obj['speckle_type']}: #{obj['id']} with displayValue.")
            convert_to_native(obj, layer)
          end
        elsif obj.is_a?(Hash)
          obj.each_value { |value| traverse_commit_object(value, commit_folder, layer) }
        elsif obj.is_a?(Array)
          obj.each { |value| traverse_commit_object(value, commit_folder, layer) }
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # @return [Sketchup::Layer] layer according to path
      def find_layer(layer_path, folder, fallback_layer)
        begin
          layer_path_array = layer_path[1..-1].split('::')
          sub_folders = layer_path_array.length > 1 ? layer_path_array[0..-2] : []
          layer_name = layer_path_array.last
          sub_folders.each do |sub_folder|
            s_f = folder.folders.find { |f| f.display_name == sub_folder }
            folder = s_f unless s_f.nil?
          end
          folder.layers.find { |l| l.display_name == layer_name }
        rescue StandardError
          return fallback_layer
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def convert_to_native(obj, layer, entities = sketchup_model.entities)
        return display_value_to_native_component(obj, layer, entities) unless obj['displayValue'].nil?

        convert = method(:convert_to_native)
        case obj['speckle_type']
        when 'Objects.Geometry.Line', 'Objects.Geometry.Polyline' then LINE.to_native(obj, layer, entities)
        when 'Objects.Other.BlockInstance' then BLOCK_INSTANCE.to_native(sketchup_model, obj, layer, entities, &convert)
        when 'Objects.Other.BlockDefinition' then BLOCK_DEFINITION.to_native(sketchup_model, obj, layer, entities, &convert)
        when 'Objects.Geometry.Mesh' then MESH.to_native(sketchup_model, obj, layer, entities)
        when 'Objects.Geometry.Brep' then MESH.to_native(sketchup_model, obj['displayValue'], layer, entities)
        end
      rescue StandardError => e
        puts("Failed to convert #{obj['speckle_type']} (id: #{obj['id']})")
        puts(e)
        nil
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # creates a component definition and instance from a speckle object with a display value
      def display_value_to_native_component(obj, layer, entities)
        obj_id = obj['applicationId'].to_s.empty? ? obj['id'] : obj['applicationId']
        definition = BLOCK_DEFINITION.to_native(
          sketchup_model,
          obj['displayValue'],
          layer,
          "def::#{obj_id}",
          &method(:convert_to_native)
        )

        find_and_erase_existing_instance(definition, obj_id)
        t_arr = obj['transform']
        transform = t_arr.nil? ? Geom::Transformation.new : OTHER::Transform.to_native(t_arr, units)
        instance = entities.add_instance(definition, transform)
        instance.name = obj_id
        instance
      end

      # takes a component definition and finds and erases the first instance with the matching name
      # (and optionally the applicationId)
      def find_and_erase_existing_instance(definition, name, app_id = '')
        definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
      end
    end
  end
end
