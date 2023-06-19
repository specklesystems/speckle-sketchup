# frozen_string_literal: true

require_relative 'event_action'
require_relative '../../mapper/category/revit_category'
require_relative '../../sketchup_model/reader/speckle_entities_reader'
require_relative '../../sketchup_model/reader/mapper_reader'
require_relative '../../sketchup_model/query/entity'

module SpeckleConnector
  module Actions
    module Events
      # Update selected speckle objects when the selection changes for mapper tool.
      class SelectionEventAction < EventAction
        # @param state [States::State] the current state of Speckle application.
        # @return [States::State] the new updated state object
        def self.update_state(state, event_data)
          return state unless event_data&.any?

          # Get sketchup selection
          sketchup_selection = state.sketchup_state.sketchup_model.selection

          # Get mapping info from selection.
          mapping = get_mapping_info(state, sketchup_selection)

          state.with_selection_queue(mapping)
        end

        def self.get_mapping_info(state, selection)
          group_by_type = selection.group_by(&:class).filter_map do |group|
            [group.first, group] if MAPPER_SUPPORTED_ENTITY_TYPES.include?(group.first)
          end.to_h
          supported_entity_count = group_by_type.length

          # Return empty method list if there is no supported entity to map.
          return EMPTY_SELECTION if supported_entity_count == 0

          # Return Direct Shape itself if multiple kinds of element are selected like Edge and Face.
          # OR single type is equal to only direct shape supports.
          if supported_entity_count > 1 ||
             (supported_entity_count == 1 &&
               MAPPER_DIRECT_SHAPE_SUPPORTED_ENTITY_TYPES.include?(group_by_type.keys.first))
            return direct_shape_selection_info(selection)
          end

          # Only single type selections remained after this point.
          return face_selection_info(state, group_by_type) if group_by_type.keys.first == Sketchup::Face

          source_exist = !state.speckle_state.speckle_mapper_state.mapper_source.nil?

          return EMPTY_SELECTION
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
          mappingMethods: [],
          categories: []
        }.freeze

        def self.direct_shape_selection_info(selection)
          {
            selection: SketchupModel::Reader::MapperReader.entities_schema_details(selection),
            mappingMethods: ['Direct Shape'],
            categories: Mapper::Category::RevitCategory.to_a
          }.freeze
        end

        def self.face_selection_info(state, faces)

        end
      end
    end
  end
end
