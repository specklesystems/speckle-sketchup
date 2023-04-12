# frozen_string_literal: true

require_relative 'converter'
require_relative 'base_object_serializer'
require_relative '../speckle_objects/base'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/length'
require_relative '../speckle_objects/geometry/mesh'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/block_definition'
require_relative '../speckle_objects/other/rendering_options'
require_relative '../speckle_objects/built_elements/view3d'
require_relative '../speckle_objects/built_elements/revit/direct_shape'
require_relative '../speckle_objects/relations/layers'
require_relative '../speckle_objects/relations/layer'
require_relative '../constants/path_constants'
require_relative '../sketchup_model/reader/speckle_entities_reader'
require_relative '../sketchup_model/query/entity'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToSpeckle < Converter
      # Convert selected objects by putting them into related array that grouped by layer.
      # @return [Hash{Symbol=>Array}] layers -which only have objects- to hold it's objects under the base object.
      def convert_selection_to_base(preferences)
        layers = add_all_layers
        state = speckle_state
        sketchup_model.selection.each do |entity|
          new_speckle_state, converted_object_with_entity = convert(entity, preferences, state)
          state = new_speckle_state
          layer_name = entity_layer_path(entity)
          layers[layer_name].push(converted_object_with_entity) unless converted_object_with_entity.nil?
        end
        layers['@DirectShape'] = direct_shapes.collect do |entities|
          from_mapped_to_speckle(entities[0], entities[1..-1], preferences)
        end
        # send only layers that have any object
        base_object_properties = layers.reject { |_layer_name, objects| objects.empty? }
        base_object_properties[:layers_relation] = create_relation_from_layers
        base_object_properties['@Named Views'] = collect_views if sketchup_model.pages.any?
        return state, SpeckleObjects::Base.with_detached_layers(base_object_properties)
      end

      # Find flatten direct shapes by calculating their path to find global transformation later.
      def direct_shapes
        flat_selection_with_path = SketchupModel::Query::Entity
                                   .flat_entities_with_path(
                                     sketchup_model.selection,
                                     [Sketchup::Face, Sketchup::ComponentInstance, Sketchup::Group], [sketchup_model]
                                   )
        mapped_selection = []
        flat_selection_with_path.each do |entities|
          entity = entities[0]
          is_entity_mapped = SketchupModel::Reader::SpeckleEntitiesReader.mapped_with_schema?(entity)
          if entity.respond_to?(:definition)
            is_definition_mapped = SketchupModel::Reader::SpeckleEntitiesReader.mapped_with_schema?(entity.definition)
            mapped_selection.append(entities) if is_entity_mapped || is_definition_mapped
            next
          end
          mapped_selection.append(entities) if is_entity_mapped
        end
        mapped_selection
      end

      # Collect views from pages.
      def collect_views
        sketchup_model.pages.collect do |page|
          SpeckleObjects::BuiltElements::View3d.from_page(page, @units)
        end
      end

      # Serialized and traversed information to send batches.
      # @param base_and_entity [SpeckleObjects::Base] base object to serialize.
      # @return [String, Integer, Array<Object>] base id, total_children_count of base and batches
      def serialize(base_and_entity, speckle_state, preferences)
        serializer = SpeckleConnector::Converters::BaseObjectSerializer.new(speckle_state, stream_id, preferences)
        t = Time.now.to_f
        id = serializer.serialize(base_and_entity)
        batches = serializer.batch_objects
        # write_to_speckle_folder(id, batches)
        puts "Generating traversed object elapsed #{Time.now.to_f - t} s"
        base_total_children_count = serializer.total_children_count(id)
        return id, base_total_children_count, batches, serializer.speckle_state
      end

      def write_to_speckle_folder(id, batches)
        folder_path = "#{HOME_PATH}/Speckle"
        file_path = "#{folder_path}/#{id}.json"
        FileUtils.mkdir_p(folder_path) unless File.exist?(folder_path)
        File.write(file_path, batches.first)
      end

      # @param entity [Sketchup::Entity] sketchup entity to convert Speckle.
      # @param speckle_state [States::SpeckleState] the current speckle state of the {States::State}
      # @param parent [Symbol, String] parent of the Sketchup Entity to be converted.
      def convert(entity, preferences, speckle_state, parent = :base)
        convert = method(:convert)

        unless SketchupModel::Reader::SpeckleEntitiesReader.mapped_with_schema?(entity)
          return from_native_to_speckle(entity, preferences, speckle_state, parent, &convert)
        end

        return speckle_state, nil
      end

      def from_mapped_to_speckle(entity, path, preferences)
        direct_shape = SpeckleObjects::BuiltElements::Revit::DirectShape
                       .from_entity(entity, path, @units, preferences)
        return [direct_shape, [entity]]
      end

      # rubocop:disable Metrics/MethodLength
      def from_native_to_speckle(entity, preferences, speckle_state, parent, &convert)
        if entity.is_a?(Sketchup::Edge)
          line = SpeckleObjects::Geometry::Line.from_edge(entity, @units, preferences[:model]).to_h
          return speckle_state, [line, [entity]]
        end

        if entity.is_a?(Sketchup::Face)
          mesh = SpeckleObjects::Geometry::Mesh.from_face(face: entity, units: @units,
                                                          model_preferences: preferences[:model])
          return speckle_state, [mesh, [entity]]
        end

        if entity.is_a?(Sketchup::Group)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_group(
            entity, @units, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return speckle_state, [block_instance, [entity]]
        end

        if entity.is_a?(Sketchup::ComponentInstance)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_component_instance(
            entity, @units, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return speckle_state, [block_instance, [entity]]
        end

        if entity.is_a?(Sketchup::ComponentDefinition)
          # Local caching
          return speckle_state, [definitions[entity.guid], [entity]] if definitions.key?(entity.guid)

          new_speckle_state, block_definition = SpeckleObjects::Other::BlockDefinition.from_definition(
            entity, @units, preferences, speckle_state, parent, &convert
          )
          definitions[entity.guid] = block_definition
          speckle_state = new_speckle_state
          return speckle_state, [block_definition, [entity]]
        end

        return speckle_state, nil
      end
      # rubocop:enable Metrics/MethodLength

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

      def convert_layers(layers)
        layers.collect do |layer|
          SpeckleObjects::Relations::Layer.new(
            name: layer.display_name,
            color: SpeckleObjects::Others::Color.to_speckle(layer.color),
            visible: layer.visible?,
            application_id: layer.persistent_id
          )
        end
      end

      def create_relation_from_layers
        # init with headless layers
        layers_and_folders = [convert_layers(sketchup_model.layers.layers)]

        # TODO: collect layers from folders
        # sketchup_model.layers.folders.each do |layer_folder|
        #
        # end
        SpeckleObjects::Relations::Layers.new(
          active: sketchup_model.active_layer.display_name,
          layers: layers_and_folders
        )
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
