# frozen_string_literal: true

require_relative 'converter'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/other/block_definition'
require_relative '../speckle_objects/other/block_instance'
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

      def initialize(state)
        super(state.sketchup_state)
      end

      def can_convert_to_native(obj)
        return false unless obj.is_a?(Hash) && obj.key?('speckle_type')

        CONVERTABLE_SPECKLE_TYPES.include?(obj['speckle_type'])
      end

      def ignored_speckle_type?(obj)
        ['Objects.BuiltElements.Revit.Parameter'].include?(obj['speckle_type'])
      end

      # @param obj [Object] speckle commit object.
      def receive_commit_object(obj, model_preferences)
        # First create layers on the sketchup before starting traversing
        filtered_layer_containers = obj.keys.filter_map { |key| key if key.start_with?('@') && key != '@Named Views' }
        create_layers(filtered_layer_containers, sketchup_model.layers)
        create_views(obj.filter_map { |key, value| value if key == '@Named Views' }, sketchup_model)
        # Define default commit layer which is the fallback
        default_commit_layer = sketchup_model.layers.layers.find { |layer| layer.display_name == '@Untagged' }
        traverse_commit_object(obj, sketchup_model.layers, default_commit_layer, model_preferences)
      end

      # Create actual Sketchup layers from layer_paths that taken from Speckle base object.
      # @param layer_paths [Array<String>] layer paths to decompose it to folders and it's layers.
      # @param folder [Sketchup::Layers, Sketchup::LayerFolder] folder to create folders and layers under it.
      def create_layers(layer_paths, folder)
        # Strip leading '@'
        layers_with_folders = layer_paths.map { |layer| layer[1..-1] }
        # Split layer_paths according to having parent folder or not.
        layers_with_head_folder, headless_layers = layers_with_folders.partition { |layer| layer.include?('::') }
        # Create array of array that split with '::'
        folder_layer_arrays = layers_with_head_folder.collect { |folder_layer| folder_layer.split('::') }
        # Add headless layers into `Sketchup.active_model.layers`
        create_headless_layers(headless_layers, folder)
        # Create layers that have parent folder(s)- this method is recursive until all tree is created.
        create_folder_layers(folder_layer_arrays, folder)
      end

      # @param views [Array] views.
      # @param sketchup_model [Sketchup::Model] active sketchup model.
      def create_views(views, sketchup_model)
        return if views.empty?

        views.first.each do |view|
          origin = view['origin']
          target = view['target']
          origin = SpeckleObjects::Geometry::Point.to_native(origin['x'], origin['y'], origin['z'], origin['units'])
          target = SpeckleObjects::Geometry::Point.to_native(target['x'], target['y'], target['z'], target['units'])
          # Set camera position before creating scene on it.
          my_camera = Sketchup::Camera.new(origin, target, [0, 0, 1], !view['isOrthogonal'], view['lens'])
          sketchup_model.active_view.camera = my_camera
          sketchup_model.pages.add(view['name'])
        end
      end

      # @param headless_layers [Array<String>] headless layer names.
      # @param folder [Sketchup::Layers, Sketchup::LayerFolder] layer folder to create commit layers under it.
      def create_headless_layers(headless_layers, folder)
        headless_layers.each do |layer_name|
          # Add layer first to the layers object of sketchup model.
          layer = sketchup_model.layers.add(layer_name)
          folder.add_layer(layer) unless folder.layers.any? { |l| l.display_name == layer_name }
        end
      end

      # Create layers with it's parent folders.
      # @param folder [Sketchup::LayerFolder] layer folder to create commit layers under it.
      def create_folder_layers(folder_layer_arrays, folder)
        folder_layer_arrays.each do |folder_layer_array|
          create_folder_layer(folder_layer_array, folder)
        end
      end

      # Create layers that have parent folder(s)- this method is recursive (self-caller) until all tree is created.
      def create_folder_layer(folder_array, folder)
        if folder_array.length > 1
          # add folder if it is not exist.
          folder.add_folder(folder_array[0]) unless folder.folders.any? { |f| f.display_name == folder_array[0] }
          new_folder = folder.folders.find { |f| f.display_name == folder_array[0] }
          create_folder_layer(folder_array[1..-1], new_folder)
        else
          # Add layer first to the layers object of sketchup model.
          layer = sketchup_model.layers.add(folder_array[0])
          folder.add_layer(layer) unless folder.layers.any? { |l| l.display_name == layer }
        end
      end

      # Traversal method to create Sketchup objects from upcoming base object.
      # @param obj [Hash, Array] object might be source base object or it's sub objects, because this method is a
      #   self-caller method means that call itself according to conditions inside of it.
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def traverse_commit_object(obj, commit_folder, layer, model_preferences)
        if can_convert_to_native(obj)
          convert_to_native(obj, layer, model_preferences)
        elsif obj.is_a?(Hash) && obj.key?('speckle_type')
          return if ignored_speckle_type?(obj)

          if obj['displayValue'].nil?
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']}. Continuing traversal.")
            props = obj.keys.filter_map { |key| key unless key.start_with?('_') }
            props.each do |prop|
              layer_path = prop if prop.start_with?('@') && obj[prop].is_a?(Array)
              layer = find_layer(layer_path, commit_folder, layer)
              traverse_commit_object(obj[prop], commit_folder, layer, model_preferences)
            end
          else
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']} with displayValue.")
            convert_to_native(obj, layer, model_preferences)
          end
        elsif obj.is_a?(Hash)
          obj.each_value { |value| traverse_commit_object(value, commit_folder, layer, model_preferences) }
        elsif obj.is_a?(Array)
          obj.each { |value| traverse_commit_object(value, commit_folder, layer, model_preferences) }
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # Find layer of the Speckle object by checking iteratively into folder.
      # @param layer_path [String] complete layer_path to retrieve
      # @param folder [Sketchup::LayerFolder, Sketchup::Layers] entry folder to search layer
      # @param fallback_layer [Sketchup::Layer] fallback layer to assign object later if any error occur.
      # @return [Sketchup::Layer] layer according to path
      # @example
      #   "@folder_1::folder_2::layer_1"
      #   # it will return the layer object which has display name as `layer_1`.
      def find_layer(layer_path, folder, fallback_layer)
        begin
          # Split folders and it's tail layer (last one is layer, others are folders.)
          layer_path_array = layer_path[1..-1].split('::')
          # Get sub folders as array, might be empty if `layer_path_array` has only 1 entry
          sub_folders = layer_path_array.length > 1 ? layer_path_array[0..-2] : []
          # Get exact layer name from last entry
          layer_name = layer_path_array.last
          # Iterate sub folders to find new sub folder to switch it.
          # It help to search in the tree by switching the target search folder.
          # Finally we can reach the layer name.
          sub_folders.each do |sub_folder|
            # Try to find sub folder into source folder passes by argument
            s_f = folder.folders.find { |f| f.display_name == sub_folder }
            # Switch source folder if any exist
            folder = s_f unless s_f.nil?
          end
          # Find finally the layer into related folder
          folder.layers.find { |l| l.display_name == layer_name }
        rescue StandardError
          return fallback_layer
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/MethodLength
      def convert_to_native(obj, layer, model_preferences, entities = sketchup_model.entities)
        convert = method(:convert_to_native)
        unless obj['displayValue'].nil?
          return display_value_to_native_component(obj, layer, entities, model_preferences, &convert)
        end

        case obj['speckle_type']
        when 'Objects.Geometry.Line', 'Objects.Geometry.Polyline' then LINE.to_native(obj, layer, entities)
        when 'Objects.Other.BlockInstance' then BLOCK_INSTANCE.to_native(sketchup_model, obj, layer, entities,
                                                                         model_preferences, &convert)
        when 'Objects.Other.BlockDefinition' then BLOCK_DEFINITION.to_native(sketchup_model, obj, layer,
                                                                             obj['name'],
                                                                             obj['always_face_camera'],
                                                                             model_preferences,
                                                                             obj['sketchup_attributes'],
                                                                             obj['applicationId'],
                                                                             &convert)
        when 'Objects.Geometry.Mesh' then MESH.to_native(sketchup_model, obj, layer, entities, model_preferences)
        when 'Objects.Geometry.Brep' then MESH.to_native(sketchup_model, obj['displayValue'], layer, entities,
                                                         model_preferences)
        end
      rescue StandardError => e
        puts("Failed to convert #{obj['speckle_type']} (id: #{obj['id']})")
        puts(e)
        nil
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength

      # Creates a component definition and instance from a speckle object with a display value
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/MethodLength
      def display_value_to_native_component(obj, layer, entities, model_preferences, &convert)
        obj_id = obj['applicationId'].to_s.empty? ? obj['id'] : obj['applicationId']

        block_definition = obj['@blockDefinition'] || obj['blockDefinition']

        definition = BLOCK_DEFINITION.to_native(
          sketchup_model,
          obj['displayValue'],
          layer,
          "def::#{obj_id}",
          if block_definition.nil?
            false
          else
            block_definition['always_face_camera'].nil? ? false : block_definition['always_face_camera']
          end,
          model_preferences,
          if block_definition.nil?
            nil
          else
            block_definition['sketchup_attributes'].nil? ? nil : block_definition['sketchup_attributes']
          end,
          obj_id,
          &convert
        )

        find_and_erase_existing_instance(definition, obj_id)
        t_arr = obj['transform']
        transform = t_arr.nil? ? Geom::Transformation.new : OTHER::Transform.to_native(t_arr, units)
        instance = entities.add_instance(definition, transform)
        instance.name = obj_id
        instance
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength

      # Takes a component definition and finds and erases the first instance with the matching name
      # (and optionally the applicationId)
      def find_and_erase_existing_instance(definition, name, app_id = '')
        definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
      end
    end
  end
end
