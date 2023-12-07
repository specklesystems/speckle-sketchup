# frozen_string_literal: true

require_relative 'action'
require_relative '../mapper/category/revit_category'
require_relative '../mapper/category/revit_family_category'
require_relative '../sketchup_model/reader/mapper_reader'
require_relative '../sketchup_model/reader/speckle_entities_reader'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module Actions
    # Collects mapper selection info.
    class MapperSelectionChanged < Action
      READER = SketchupModel::Reader
      DICTIONARY = SketchupModel::Dictionary

      def initialize(selection)
        super()
        @selection = selection
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        # Get mapping info from selection.
        mapping = get_mapping_info(state, @selection)

        state.with_mapper_selection_queue(mapping)
      end

      def filter_out_levels(selection)
        selection.reject do |e|
          DICTIONARY::SpeckleEntityDictionaryHandler
            .get_attribute(e, :speckle_type) == OBJECTS_BUILTELEMENTS_REVIT_LEVEL
        end
      end

      def get_mapping_info(state, selection)
        source_exist = !state.speckle_state.speckle_mapper_state.mapper_source.nil?
        selection = filter_out_levels(selection)
        grouped_by_type = group_by_type(selection)

        supported_entity_count = grouped_by_type.length

        # Return empty method list if there is no supported entity to map.
        return EMPTY_SELECTION if supported_entity_count == 0

        # Return Direct Shape itself if multiple kinds of element are selected like Edge and Face.
        # OR single type is equal to only direct shape supports.
        return multiple_supported_selection_info(selection) if supported_entity_count > 1

        # FIXME: Distinguish selection info according to selection elegantly!!!
        if grouped_by_type.keys.first == Sketchup::ComponentInstance
          return component_selection_info(selection, source_exist)
        end

        return group_selection_info(selection) if grouped_by_type.keys.first == Sketchup::Group

        if supported_entity_count > 1 ||
           (supported_entity_count == 1 &&
             MAPPER_DIRECT_SHAPE_SUPPORTED_ENTITY_TYPES.include?(grouped_by_type.keys.first))
          if source_exist
            return direct_shape_selection_info_with_source(selection, [])
          else
            return direct_shape_selection_info(selection, source_exist)
          end
        end

        # Only single type selections remained after this point.
        return face_selection_info(state, grouped_by_type.values.first) if grouped_by_type.keys.first == Sketchup::Face

        return edge_selection_info(state, grouped_by_type.values.first) if grouped_by_type.keys.first == Sketchup::Edge

        EMPTY_SELECTION
      end

      MAPPER_SUPPORTED_ENTITY_TYPES = [
        Sketchup::ComponentInstance,
        Sketchup::Group,
        Sketchup::Face,
        Sketchup::Edge
      ].freeze

      MAPPER_DIRECT_SHAPE_SUPPORTED_ENTITY_TYPES = [
        Sketchup::ComponentInstance,
        Sketchup::Group
      ].freeze

      EMPTY_SELECTION = {
        selection: [],
        mappingMethods: []
      }.freeze

      def multiple_supported_selection_info(selection)
        {
          selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
          mappingMethods: ['Direct Shape']
        }.freeze
      end

      def component_selection_info(selection, source_exist)
        if source_exist
          {
            selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
            mappingMethods: ['New Revit Family', 'Family Instance']
          }.freeze
        else
          {
            selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
            mappingMethods: ['New Revit Family']
          }.freeze
        end
      end

      def group_selection_info(selection)
        {
          selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
          mappingMethods: ['Direct Shape']
        }.freeze
      end

      def direct_shape_selection_info(selection, source_exist)
        methods = ['Direct Shape', 'New Revit Family']
        methods.append('Family Instance') if source_exist
        {
          selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
          mappingMethods: methods
        }.freeze
      end

      def direct_shape_selection_info_with_default(selection, methods)
        {
          selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
          mappingMethods: ['Direct Shape'] + methods
        }.freeze
      end

      def direct_shape_selection_info_with_source(filtered_selection, methods)
        instances = @selection.grep(Sketchup::ComponentInstance)
        selected_level = instances.find do |i|
          DICTIONARY::SpeckleEntityDictionaryHandler
            .get_attribute(i, :speckle_type) == OBJECTS_BUILTELEMENTS_REVIT_LEVEL
        end
        selected_level_name = nil
        if selected_level
          selected_level_name = DICTIONARY::SpeckleEntityDictionaryHandler.get_attribute(selected_level, :name)
        end
        {
          selection: READER::MapperReader.entities_schema_details(filtered_selection),
          mappingMethods: ['Direct Shape'] + methods,
          categories: Mapper::Category::RevitCategory.to_a,
          selectedLevelName: selected_level_name
        }.freeze
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      def face_selection_info(state, faces)
        source_exist = !state.speckle_state.speckle_mapper_state.mapper_source.nil?
        grouped_by_verticality = faces.group_by { |face| face.normal.perpendicular?(VECTOR_Z) }
        return direct_shape_selection_info(faces, source_exist) if grouped_by_verticality.length == 2

        if source_exist
          if grouped_by_verticality.keys.first
            direct_shape_selection_info_with_source(faces, ['Wall'])
          else
            direct_shape_selection_info_with_source(faces, ['Floor'])
          end
        else
          if grouped_by_verticality.keys.first
            direct_shape_selection_info_with_default(faces, ['Default Wall'])
          else
            direct_shape_selection_info_with_default(faces, ['Default Floor'])
          end
        end
      end

      def edge_selection_info(state, edges)
        source_exist = !state.speckle_state.speckle_mapper_state.mapper_source.nil?

        if source_exist
          methods = ['Column', 'Beam', 'Pipe', 'Duct']
          direct_shape_selection_info_with_source(edges, methods)
        else
          default_methods = ['Default Column', 'Default Beam', 'Default Pipe', 'Default Duct']
          direct_shape_selection_info_with_default(edges, default_methods)
        end
      end

      def group_by_type_old(selection)
        selection.group_by(&:class).filter_map do |group|
          [group.first, group] if MAPPER_SUPPORTED_ENTITY_TYPES.include?(group.first)
        end.to_h
      end

      def group_by_type(selection)
        selection.select { |s| MAPPER_SUPPORTED_ENTITY_TYPES.include?(s.class) }.group_by(&:class)
      end
    end
  end
end
