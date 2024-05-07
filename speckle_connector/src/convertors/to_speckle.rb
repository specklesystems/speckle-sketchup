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
require_relative '../speckle_objects/speckle/core/models/model_collection'
require_relative '../constants/path_constants'
require_relative '../sketchup_model/reader/speckle_entities_reader'
require_relative '../sketchup_model/reader/mapper_reader'
require_relative '../sketchup_model/query/entity'
require_relative '../ext/TT_Lib2/progressbar'
require_relative '../ext/TT_Lib2/model'
require_relative '../ext/TT_Lib2/entities'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToSpeckle < Converter
      MODEL_COLLECTION = SpeckleObjects::Speckle::Core::Models::ModelCollection
      DIRECT_SHAPE = SpeckleObjects::BuiltElements::Revit::DirectShape
      SPECKLE_ENTITIES_READER = SketchupModel::Reader::SpeckleEntitiesReader
      VIEW3D = SpeckleObjects::BuiltElements::View3d

      # @return [TT::ProgressBar]
      attr_reader :progress_bar

      attr_reader :send_filter

      def initialize(state, stream_id, send_filter)
        super(state, stream_id)
        @send_filter = send_filter
        model = state.sketchup_state.sketchup_model
        entity_count = if send_filter.name == 'Selection'
                         TT::Model.count_unique_entity(model)
                       else
                         TT::Entities.count_unique_entity(model.selection)
                       end
        @progress_bar = TT::Progressbar.new(entity_count, 'Converting to Speckle')
      end

      # @return [States::SpeckleState, SpeckleObjects::Speckle::Core::Models::ModelCollection]
      def convert_entities_to_base(entity_ids, preferences)
        convert = method(:convert)
        entities = sketchup_model.entities.select { |e| entity_ids.any?(e.persistent_id) }

        new_speckle_state, model_collection = MODEL_COLLECTION.from_entities(entities, sketchup_model, speckle_state,
                                                                             @units, preferences, &convert)

        return new_speckle_state, model_collection
      end

      # Convert selected objects by putting them into related array that grouped by layer.
      # @return [Hash{Symbol=>Array}] layers -which only have objects- to hold it's objects under the base object.
      def convert_selection_to_base(preferences)
        convert = method(:convert)
        new_speckle_state, model_collection = MODEL_COLLECTION.from_sketchup_model(sketchup_model, speckle_state,
                                                                                   @units, preferences, &convert)

        return new_speckle_state, model_collection
      end

      # Serialized and traversed information to send batches.
      # @param base_and_entity [SpeckleObjects::Base] base object to serialize.
      # @return [String, Integer, Array<Object>] base id, total_children_count of base and batches
      def serialize(base_and_entity, preferences)
        serializer = SpeckleConnector::Converters::BaseObjectSerializer.new(preferences)
        t = Time.now.to_f
        id = serializer.serialize(base_and_entity)
        batches = serializer.batch_json_objects
        write_to_speckle_folder(id, batches)
        puts "Generating traversed object elapsed #{(Time.now.to_f - t).round(5)} s"
        base_total_children_count = serializer.total_children_count(id)
        return id, base_total_children_count, batches, serializer.object_references
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
        progress_bar.next
        convert = method(:convert)

        unless SketchupModel::Reader::MapperReader.mapped_with_schema?(entity) &&
               !entity.is_a?(Sketchup::ComponentDefinition)
          return from_native_to_speckle(entity, preferences, speckle_state, parent, &convert)
        end

        return speckle_state, nil
      end

      # @param entity [Sketchup::Entity]
      def entity_has_changed?(entity)
        speckle_state.changed_entity_persistent_ids.include?(entity.persistent_id) ||
          speckle_state.changed_entity_ids.include?(entity.entityID)
      end

      # @param entity [Sketchup::Entity]
      # @param speckle_state [States::SpeckleState]
      # rubocop:disable Metrics/MethodLength
      def from_native_to_speckle(entity, preferences, speckle_state, parent, &convert)
        # Where we do send caching!
        if !entity_has_changed?(entity) &&
           speckle_state.object_references_by_project[@stream_id] &&
           speckle_state.object_references_by_project[@stream_id].keys.include?(entity.persistent_id.to_s)
          reference = speckle_state.object_references_by_project[@stream_id][entity.persistent_id.to_s]
          return speckle_state, reference
        end

        if entity.is_a?(Sketchup::Edge)
          line = SpeckleObjects::Geometry::Line.from_edge(speckle_state: speckle_state, edge: entity,
                                                          units: @units, model_preferences: preferences[:model]).to_h
          return speckle_state, line
        end

        if entity.is_a?(Sketchup::Face)
          mesh = SpeckleObjects::Geometry::Mesh.from_face(speckle_state: speckle_state, face: entity, units: @units,
                                                          model_preferences: preferences[:model])
          return speckle_state, mesh
        end

        if entity.is_a?(Sketchup::Group)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_group(
            entity, @units, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return speckle_state, block_instance
        end

        if entity.is_a?(Sketchup::ComponentInstance)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_component_instance(
            entity, @units, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          return speckle_state, block_instance
        end

        if entity.is_a?(Sketchup::ComponentDefinition)
          # Local caching
          return speckle_state, definitions[entity.guid] if definitions.key?(entity.guid)

          new_speckle_state, block_definition = SpeckleObjects::Other::BlockDefinition.from_definition(
            entity, @units, preferences, speckle_state, parent, &convert
          )
          definitions[entity.guid] = block_definition
          speckle_state = new_speckle_state
          return speckle_state, block_definition
        end

        return speckle_state, nil
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
