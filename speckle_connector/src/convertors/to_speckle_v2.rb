# frozen_string_literal: true

require_relative 'converter_v2'
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
require_relative '../sketchup_model/definitions/definition_manager'
require_relative '../ui_data/report/conversion_result'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToSpeckleV2 < ConverterV2
      MODEL_COLLECTION = SpeckleObjects::Speckle::Core::Models::ModelCollection
      DIRECT_SHAPE = SpeckleObjects::BuiltElements::Revit::DirectShape
      SPECKLE_ENTITIES_READER = SketchupModel::Reader::SpeckleEntitiesReader
      VIEW3D = SpeckleObjects::BuiltElements::View3d

      attr_reader :send_filter

      attr_reader :conversion_results

      # @return [SketchupModel::Definitions::UnpackResult]
      attr_reader :unpacked_entities

      # @param model_card [Cards::SendCard] sender card
      def initialize(state, unpacked_entities, model_card)
        super(state, model_card)
        @send_filter = model_card.send_filter
        @conversion_results = []
        @unpacked_entities = unpacked_entities
      end

      def convert_entities_to_base_blocks_poc
        convert = method(:convert)

        # start_time = Time.now.to_f
        # puts "Number of atomic objects: #{unpacked_entities.atomic_objects.length}"
        new_speckle_state, model_collection = MODEL_COLLECTION.from_atomic_entities(unpacked_entities.atomic_objects,
                                                                                    state, model_card.model_card_id,
                                                                                    &convert)
        # elapsed_time = (Time.now.to_f - start_time).round(3)
        # puts "==== New Blocks: Converting to Speckle executed in #{elapsed_time} sec ===="

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
      def convert(entity, preferences, speckle_state, parent = :base, ignore_cache = false)
        convert = method(:convert)

        unless SketchupModel::Reader::MapperReader.mapped_with_schema?(entity) &&
               !entity.is_a?(Sketchup::ComponentDefinition)
          return from_native_to_speckle(entity, preferences, speckle_state, parent, ignore_cache, &convert)
        end
      rescue StandardError => e
        @conversion_results.push(UiData::Report::ConversionResult.new(UiData::Report::ConversionStatus::ERROR,
                                                                      entity.persistent_id,
                                                                      entity.class,
                                                                      nil,
                                                                      nil,
                                                                      e))
        return speckle_state, nil
      end

      # @param entity [Sketchup::Entity]
      def entity_has_changed?(entity)
        speckle_state.changed_entity_persistent_ids.include?(entity.persistent_id) ||
          speckle_state.changed_entity_ids.include?(entity.entityID)
      end

      def add_to_report(entity, converted)
        @conversion_results.push(UiData::Report::ConversionResult.new(UiData::Report::ConversionStatus::SUCCESS,
                                                                      entity.persistent_id,
                                                                      entity.class,
                                                                      converted[:id],
                                                                      converted[:speckle_type]))
      end

      # @param entity [Sketchup::Entity]
      # @param speckle_state [States::SpeckleState]
      # rubocop:disable Metrics/MethodLength
      def from_native_to_speckle(entity, preferences, speckle_state, parent, ignore_cache, &convert)
        # Where we do send caching!
        if !ignore_cache && !entity_has_changed?(entity) &&
           speckle_state.object_references_by_project[model_card.project_id] &&
           speckle_state.object_references_by_project[model_card.project_id].keys.include?(entity.persistent_id.to_s)
          reference = speckle_state.object_references_by_project[model_card.project_id][entity.persistent_id.to_s]
          add_to_report(entity, reference)
          return speckle_state, reference
        end

        if entity.is_a?(Sketchup::Edge)
          line = SpeckleObjects::Geometry::Line.from_edge(speckle_state: speckle_state, edge: entity,
                                                          units: @units, model_preferences: preferences[:model]).to_h
          add_to_report(entity, line)
          return speckle_state, line
        end

        if entity.is_a?(Sketchup::Face)
          mesh = SpeckleObjects::Geometry::Mesh.from_face(speckle_state: speckle_state, face: entity, units: @units,
                                                          model_preferences: preferences[:model])
          add_to_report(entity, mesh)
          return speckle_state, mesh
        end

        if entity.is_a?(Sketchup::Group)
          new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_group(
            entity, @units, preferences, speckle_state, &convert
          )
          speckle_state = new_speckle_state
          add_to_report(entity, block_instance)
          return speckle_state, block_instance
        end

        if entity.is_a?(Sketchup::ComponentInstance)
          proxy = unpacked_entities.instance_proxies[entity.persistent_id.to_s]
          add_to_report(entity, proxy)
          return speckle_state, proxy
          # new_speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_component_instance(
          #   entity, @units, preferences, speckle_state, &convert
          # )
          # speckle_state = new_speckle_state
          # add_to_report(entity, block_instance)
          # return speckle_state, block_instance
        end

        if entity.is_a?(Sketchup::ComponentDefinition)
          # Local caching
          return speckle_state, definitions[entity.guid] if definitions.key?(entity.guid)

          new_speckle_state, block_definition = SpeckleObjects::Other::BlockDefinition.from_definition(
            entity, @units, preferences, speckle_state, parent, &convert
          )
          definitions[entity.guid] = block_definition
          speckle_state = new_speckle_state
          add_to_report(entity, block_definition)
          return speckle_state, block_definition
        end

        raise StandardError.new("No conversion found for #{entity.class}.")
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
