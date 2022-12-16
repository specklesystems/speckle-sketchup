# frozen_string_literal: true

require_relative 'converter'
require_relative 'base_object_serializer'
require_relative '../relations/many_to_one_relation'
require_relative '../speckle_entities/speckle_entities'
require_relative '../speckle_objects/base'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/length'
require_relative '../speckle_objects/geometry/mesh'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/block_definition'
require_relative '../speckle_objects/built_elements/view3d'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToSpeckle < Converter
      # @return [Hash{Symbol=>Array}] layers to hold it's objects under the base object.
      attr_reader :layers

      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_reader :speckle_state

      # @return [Relations::ManyToOneRelation] relations between objects.
      attr_reader :converted_relation

      def initialize(state)
        super(state.sketchup_state)
        @state = state
        @speckle_state = @state.speckle_state
        @layers = add_all_layers
        @converted_relation = Relations::ManyToOneRelation.new
      end

      def traverse_selection
        state = speckle_state
        sketchup_model.selection.each do |selected_entity|
          new_speckle_state, converted_object = convert(selected_entity, state)
          state = new_speckle_state
          layer_name = entity_layer_path(selected_entity)
          layers[layer_name].push(converted_object)
        end
      end

      # Convert selected objects by putting them into related array that grouped by layer.
      # @return [Hash{Symbol=>Array}] layers -which only have objects- to hold it's objects under the base object.
      def convert_selection_to_base(preferences)
        state = speckle_state
        sketchup_model.selection.each do |entity|
          new_speckle_state, converted_object = convert(entity, preferences, state)
          state = new_speckle_state
          layer_name = entity_layer_path(entity)
          layers[layer_name].push(converted_object)
        end
        # send only layers that have any object
        base_object_properties = layers.reject { |_layer_name, objects| objects.empty? }
        add_views(base_object_properties) if sketchup_model.pages.any?
        SpeckleObjects::Base.with_detached_layers(base_object_properties)
      end

      # Add views from pages.
      # @param base_object_properties [Hash] dynamically attached base object properties.
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def add_views(base_object_properties)
        views = []
        sketchup_model.pages.each do |page|
          cam = page.camera
          origin = SpeckleObjects::Geometry::Point.new(
            SpeckleObjects::Geometry.length_to_speckle(cam.eye[0], @units),
            SpeckleObjects::Geometry.length_to_speckle(cam.eye[1], @units),
            SpeckleObjects::Geometry.length_to_speckle(cam.eye[2], @units),
            @units
          )
          target = SpeckleObjects::Geometry::Point.new(
            SpeckleObjects::Geometry.length_to_speckle(cam.target[0], @units),
            SpeckleObjects::Geometry.length_to_speckle(cam.target[1], @units),
            SpeckleObjects::Geometry.length_to_speckle(cam.target[2], @units),
            @units
          )
          direction = SpeckleObjects::Geometry::Vector.new(
            SpeckleObjects::Geometry.length_to_speckle(cam.direction[0], @units),
            SpeckleObjects::Geometry.length_to_speckle(cam.direction[1], @units),
            SpeckleObjects::Geometry.length_to_speckle(cam.direction[2], @units),
            @units
          )
          view = SpeckleObjects::BuiltElements::View3d.new(
            page.name,
            origin, target, direction, SpeckleObjects::Geometry::Vector.new(0, 0, 1, @units),
            cam.perspective?, cam.fov, @units, page.name
          )
          views.append(view)
        end
        base_object_properties['@Named Views'] = views
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # Serialized and traversed information to send batches.
      # @param base [SpeckleObjects::Base] base object to serialize.
      # @return [String, Integer, Array<Object>] base id, total_children_count of base and batches
      def send_info(base)
        serializer = SpeckleConnector::Converters::BaseObjectSerializer.new
        # t = Time.now.to_f
        new_speckle_state, id, _traversed, _objects = serializer.serialize(base, speckle_state)
        # puts "Generating traversed object elapsed #{Time.now.to_f - t} s"
        base_total_children_count = serializer.total_children_count(id)
        # puts '#####################'
        # puts serializer.batch_objects
        # puts '#####################'
        return new_speckle_state, id, base_total_children_count, serializer.batch_objects
      end

      # @param speckle_state [States::SpeckleState] the current speckle state of the {States::State}
      def serialize(converted, speckle_state, parent, entity)
        serializer = SpeckleConnector::Converters::BaseObjectSerializer.new
        new_speckle_state, id, _traversed, objects = serializer.serialize(converted, speckle_state)
        speckle_entity = SpeckleEntities.with_converted(entity, objects, parent)
        speckle_state = speckle_state.with_speckle_entity(speckle_entity)
        converted_relation.add(id, parent)
        return speckle_state, converted
      end

      # @param entity [Sketchup::Entity] sketchup entity to convert Speckle.
      # @param speckle_state [States::SpeckleState] the current speckle state of the {States::State}
      # @param parent [Symbol, String] parent of the Sketchup Entity to be converted.
      def convert(entity, preferences, speckle_state, parent = :base)
        convert = method(:convert)

        if entity.is_a?(Sketchup::Edge)
          line = SpeckleObjects::Geometry::Line.from_edge(entity, @units, preferences[:model]).to_h
          return serialize(line, speckle_state, parent)
        end

        if entity.is_a?(Sketchup::Face)
          mesh = SpeckleObjects::Geometry::Mesh.from_face(entity, @units, preferences[:model])
          return serialize(mesh, speckle_state, parent)
        end

        if entity.is_a?(Sketchup::Group)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_group(
            entity, @units, @definitions, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return serialize(block_instance, speckle_state, parent, entity)
        end

        if entity.is_a?(Sketchup::ComponentInstance)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_component_instance(
            entity, @units, @definitions, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return serialize(block_instance, speckle_state, parent, entity)
        end
        
        if entity.is_a?(Sketchup::ComponentDefinition)
          new_speckle_state, block_definition = SpeckleObjects::Other::BlockDefinition.from_definition(
            entity, @units, @definitions, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return serialize(block_definition, speckle_state, parent, entity)

        return speckle_state, nil
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
