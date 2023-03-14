# frozen_string_literal: true

require_relative 'converter'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/other/block_definition'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/display_value'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/mesh'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    # rubocop:disable Metrics/ClassLength
    class ToNative < Converter
      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_accessor :speckle_state

      # @return [String] source application of received object that will be converted to native
      attr_reader :source_app

      def initialize(state, stream_id, stream_name, branch_name, source_app)
        super(state, stream_id)
        @stream_name = stream_name
        @branch_name = branch_name
        @source_app = source_app.downcase
      end

      # Module aliases
      GEOMETRY = SpeckleObjects::Geometry
      OTHER = SpeckleObjects::Other

      # Class aliases
      POINT = GEOMETRY::Point
      LINE = GEOMETRY::Line
      MESH = GEOMETRY::Mesh
      BLOCK_DEFINITION = OTHER::BlockDefinition
      BLOCK_INSTANCE = OTHER::BlockInstance
      RENDER_MATERIAL = OTHER::RenderMaterial
      DISPLAY_VALUE = OTHER::DisplayValue

      BASE_OBJECT_PROPS = %w[applicationId id speckle_type totalChildrenCount].freeze
      CONVERTABLE_SPECKLE_TYPES = %w[
        Objects.Geometry.Line
        Objects.Geometry.Polyline
        Objects.Geometry.Mesh
        Objects.Geometry.Brep
        Objects.Other.BlockInstance
        Objects.Other.Revit.RevitInstance
        Objects.Other.BlockDefinition
        Objects.Other.RenderMaterial
      ].freeze

      def from_revit
        @from_revit ||= source_app.include?('revit')
      end

      def from_sketchup
        @from_sketchup ||= source_app.include?('sketchup')
      end

      # ReceiveObjects action call this method by giving everything that comes from server.
      # Upcoming object is a referencedObject of selected commit to receive.
      # UI is responsible currently to fetch objects from ObjectLoader module by calling getAndConstruct method.
      # @param obj [Object] speckle commit object.
      def receive_commit_object(obj)
        # First create layers on the sketchup before starting traversing
        # @Named Views are exception here. It does not mean a layer. But it is anti-pattern for now.
        filtered_layer_containers = obj.keys.filter_map { |key| key if key.start_with?('@') && key != '@Named Views' }
        create_layers(filtered_layer_containers, sketchup_model.layers)
        views = collect_views(obj)
        create_views(views, sketchup_model)
        # Get default commit layer from sketchup model which will be used as fallback
        default_commit_layer = sketchup_model.layers.layers.find { |layer| layer.display_name == '@Untagged' }
        @entities_to_fill = entities_to_fill(obj)
        traverse_commit_object(obj, sketchup_model.layers, default_commit_layer, @entities_to_fill)
        create_levels_from_section_planes
        check_hiding_layers_needed
        @state
      end

      # Create levels from section planes that already created for this commit object.
      def create_levels_from_section_planes
        return unless from_revit

        section_planes = @entities_to_fill.grep(Sketchup::SectionPlane)
        bbox = @entities_to_fill.parent.bounds
        c_1 = bbox.corner(0)
        c_2 = bbox.corner(1)
        c_3 = bbox.corner(3)
        c_4 = bbox.corner(2)
        section_planes.each do |section_plane|
          level_name = "#{@definition_name}-#{section_plane.name}"
          definition = sketchup_model.definitions.add(level_name)
          @entities_to_fill.add_instance(definition, Geom::Transformation.new)
          elevation = section_plane.bounds.center.z
          c1_e = Geom::Point3d.new(c_1.x, c_1.y, elevation - LEVEL_SHIFT_VALUE)
          c2_e = Geom::Point3d.new(c_2.x, c_2.y, elevation - LEVEL_SHIFT_VALUE)
          c3_e = Geom::Point3d.new(c_3.x, c_3.y, elevation - LEVEL_SHIFT_VALUE)
          c4_e = Geom::Point3d.new(c_4.x, c_4.y, elevation - LEVEL_SHIFT_VALUE)
          definition.entities.add_cline(c1_e, c2_e)
          definition.entities.add_cline(c2_e, c3_e)
          definition.entities.add_cline(c3_e, c4_e)
          definition.entities.add_cline(c4_e, c1_e)
          definition.entities.add_text(" #{section_plane.name}", c1_e)
        end
      end

      def entities_to_fill(_obj)
        return sketchup_model.entities if from_sketchup

        @definition_name = "#{@branch_name}-#{@stream_name}"
        definition = sketchup_model.definitions.find { |d| d.name == @definition_name }
        if definition.nil?
          definition = sketchup_model.definitions.add(@definition_name)
          sketchup_model.entities.add_instance(definition, Geom::Transformation.new)
        end
        definition.entities
      end

      LAYERS_WILL_BE_HIDDEN = [
        'Rooms',
        'Mass',
        'Mass Floor',
        'Grid',
        'Shaft Openings'
      ].freeze

      def check_hiding_layers_needed
        return unless from_revit

        sketchup_model.layers.each do |layer|
          if LAYERS_WILL_BE_HIDDEN.any? { |layer_name| layer.display_name.include?(layer_name) }
            layer.visible = false
            sketchup_model.pages.each { |page| page.update(PAGE_USE_LAYER_VISIBILITY) }
          end
        end
      end

      # Conditions for converting speckle object to native sketchup entity:
      #  1- `obj` is a hash
      #  2- `obj` has a property as 'speckle_type'
      #  3- `obj` is a convertable 'speckle_type' which sketchup supports
      # @param obj [Object] candidate object to convert from speckle to sketchup.
      # @return [Boolean] whether object is convertable or not.
      def convertible_to_native?(obj)
        return false unless obj.is_a?(Hash) && obj.key?('speckle_type')

        CONVERTABLE_SPECKLE_TYPES.include?(obj['speckle_type'])
      end

      def ignored_speckle_type?(obj)
        ['Objects.BuiltElements.Revit.Parameter'].include?(obj['speckle_type'])
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

      def collect_views(obj)
        views = []
        views += obj.filter_map { |key, value| value if key == '@Named Views' }
        views += obj.filter_map { |key, value| value if key == '@Views' } if from_revit
        views.flatten
      end

      # @param views [Array] views.
      # @param sketchup_model [Sketchup::Model] active sketchup model.
      # rubocop:disable Metrics/AbcSize
      def create_views(views, sketchup_model)
        return if views.empty?

        views.each do |view|
          next unless view['speckle_type'] == 'Objects.BuiltElements.View:Objects.BuiltElements.View3D'

          name = view['name'] || view['id']
          next if sketchup_model.pages.any? { |page| page.name == name }

          origin = view['origin']
          target = view['target']
          lens = view['lens'] || 50
          origin = SpeckleObjects::Geometry::Point.to_native(origin['x'], origin['y'], origin['z'], origin['units'])
          target = SpeckleObjects::Geometry::Point.to_native(target['x'], target['y'], target['z'], target['units'])
          # Set camera position before creating scene on it.
          my_camera = Sketchup::Camera.new(origin, target, [0, 0, 1], !view['isOrthogonal'], lens)
          sketchup_model.active_view.camera = my_camera
          sketchup_model.pages.add(name)
          page = sketchup_model.pages[name]
          set_page_update_properties(page, view['update_properties']) if view['update_properties']
          set_rendering_options(page.rendering_options, view['rendering_options']) if view['rendering_options']
        end
      end
      # rubocop:enable Metrics/AbcSize

      # @param page [Sketchup::Page] scene to update -update properties-
      def set_page_update_properties(page, update_properties)
        update_properties.each do |prop, value|
          page.instance_variable_set(:"@#{prop}", value)
        end
      end

      # @param rendering_options [Sketchup::RenderingOptions] rendering options of scene (page)
      def set_rendering_options(rendering_options, speckle_rendering_options)
        speckle_rendering_options.each do |prop, value|
          next if rendering_options[prop].nil?

          rendering_options[prop] = if value.is_a?(Hash)
                                      SpeckleObjects::Others::Color.to_native(value)
                                    else
                                      value
                                    end
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
      def traverse_commit_object(obj, commit_folder, layer, entities)
        if convertible_to_native?(obj)
          @state = convert_to_native(@state, obj, layer, entities)
        elsif obj.is_a?(Hash) && obj.key?('speckle_type')
          return if ignored_speckle_type?(obj)

          if obj['displayValue'].nil?
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']}. Continuing traversal.")
            props = obj.keys.filter_map { |key| key unless key.start_with?('_') }
            props.each do |prop|
              layer_path = prop if prop.start_with?('@') && obj[prop].is_a?(Array)
              layer = find_layer(layer_path, commit_folder, layer)
              traverse_commit_object(obj[prop], commit_folder, layer, entities)
            end
          else
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']} with displayValue.")
            @state = convert_to_native(@state, obj, layer, entities)
          end
        elsif obj.is_a?(Hash)
          obj.each_value { |value| traverse_commit_object(value, commit_folder, layer, entities) }
        elsif obj.is_a?(Array)
          obj.each { |value| traverse_commit_object(value, commit_folder, layer, entities) }
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

      def speckle_object_to_native(obj)
        return DISPLAY_VALUE.method(:to_native) unless obj['displayValue'].nil?

        SPECKLE_OBJECT_TO_NATIVE[obj['speckle_type']]
      end

      SPECKLE_OBJECT_TO_NATIVE = {
        OBJECTS_GEOMETRY_LINE => LINE.method(:to_native),
        OBJECTS_GEOMETRY_POLYLINE => LINE.method(:to_native),
        OBJECTS_GEOMETRY_MESH => MESH.method(:to_native),
        OBJECTS_GEOMETRY_BREP => MESH.method(:to_native),
        OBJECTS_OTHER_BLOCKDEFINITION => BLOCK_DEFINITION.method(:to_native),
        OBJECTS_OTHER_BLOCKINSTANCE => BLOCK_INSTANCE.method(:to_native),
        OBJECTS_OTHER_REVIT_REVITINSTANCE => BLOCK_INSTANCE.method(:to_native),
        OBJECTS_OTHER_RENDERMATERIAL => RENDER_MATERIAL.method(:to_native)
      }.freeze

      # @param state [States::State] state of the speckle application
      def convert_to_native(state, obj, layer, entities = sketchup_model.entities)
        # store this method as parameter to re-call it inner callstack
        convert_to_native = method(:convert_to_native)
        # Get 'to_native' method to convert upcoming speckle object to native sketchup entity
        to_native_method = speckle_object_to_native(obj)
        # Call 'to_native' method by passing this method itself to handle nested 'to_native' conversions.
        # It returns updated state and converted entities.
        state, converted_entities = to_native_method.call(state, obj, layer, entities, &convert_to_native)
        if from_revit
          # Create levels as section planes if they exists
          create_levels(state, obj)
          # Create layers from category of object and place object in it
          create_layers_from_categories(state, obj, converted_entities)
        end
        # Create speckle entities from sketchup entities to achieve continuous traversal.
        convert_to_speckle_entities(state, obj, converted_entities)
      rescue StandardError => e
        puts("Failed to convert #{obj['speckle_type']} (id: #{obj['id']})")
        puts(e)
        return state
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def create_layers_from_categories(state, speckle_object, entities)
        return state if speckle_object['category'].nil?

        layer = sketchup_model.layers.find { |l| l.display_name == speckle_object['category'] }
        unless layer.nil?
          entities.each { |entity| entity.layer = layer } if layer
          return state
        end

        layer = sketchup_model.layers.add(speckle_object['category'])
        unless layer.nil?
          entities.each { |entity| entity.layer = layer } if layer
          state
        end
        state
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # @param state [States::State] state of the speckle application
      def create_levels(state, speckle_object)
        return state if speckle_object['level'].nil?
        return state unless speckle_object['level']['speckle_type'].include?('Objects.BuiltElements.Level')

        level_name = speckle_object['level']['name'] || speckle_object['level']['id']
        is_exist = @entities_to_fill.grep(Sketchup::SectionPlane).any? { |sp| sp.name == level_name }
        return state if is_exist

        elevation = SpeckleObjects::Geometry.length_to_native(speckle_object['level']['elevation'],
                                                              speckle_object['level']['units'])

        section_plane = @entities_to_fill.add_section_plane([0, 0, elevation + LEVEL_SHIFT_VALUE], [0, 0, -1])
        section_plane.name = level_name
        state
      end

      # @param state [States::State] state of the application
      def convert_to_speckle_entities(state, speckle_object, entities)
        speckle_id = speckle_object['id']
        application_id = speckle_object['applicationId']
        speckle_type = speckle_object['speckle_type']
        children = speckle_object['__closure'].nil? ? [] : speckle_object['__closure']
        speckle_state = state.speckle_state
        entities.each do |entity|
          next if (entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)) &&
                  !state.user_state.user_preferences[:register_speckle_entity]

          ent = SpeckleEntities::SpeckleEntity.new(entity, speckle_id, application_id, speckle_type, children,
                                                   [stream_id])
          ent.write_initial_base_data
          speckle_state = speckle_state.with_speckle_entity(ent)
        end
        state.with_speckle_state(speckle_state)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
