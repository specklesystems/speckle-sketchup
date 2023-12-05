# frozen_string_literal: true

require_relative '../speckle_objects/built_elements/revit/revit_floor'
require_relative '../speckle_objects/built_elements/revit/revit_wall'
require_relative '../speckle_objects/built_elements/default_floor'
require_relative '../speckle_objects/built_elements/default_wall'
require_relative '../speckle_objects/other/mapped_block_wrapper'
require_relative '../sketchup_model/query/entity'
require_relative '../sketchup_model/reader/mapper_reader'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  # Mapper is a tool to convert SketchUp entities to other applications' native objects.
  module Mapper
    # Collects mapped entities on selection as flat list.
    def self.mapped_entities_on_selection(sketchup_model)
      flat_selection_with_path = SketchupModel::Query::Entity.flat_entities_with_path(
        sketchup_model.selection,
        [Sketchup::Face, Sketchup::ComponentInstance, Sketchup::Group], [sketchup_model]
      )
      mapped_selection = []
      flat_selection_with_path.each do |entities|
        entity = entities[0]
        is_entity_mapped = SketchupModel::Reader::MapperReader.mapped_with_schema?(entity)
        if entity.respond_to?(:definition)
          is_definition_mapped = SketchupModel::Reader::MapperReader.mapped_with_schema?(entity.definition)
          mapped_selection.append(entities) if is_entity_mapped || is_definition_mapped
          next
        end
        mapped_selection.append(entities) if is_entity_mapped
      end
      mapped_selection
    end

    def self.to_speckle(speckle_state, entity, units, model_preferences, global_transformation: nil, path: nil)
      speckle_schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.speckle_schema_to_speckle(entity)
      return speckle_schema if speckle_schema.nil?

      if speckle_schema['method'] == 'Default Floor'
        return SpeckleObjects::BuiltElements::DefaultFloor
               .to_speckle_schema(entity, units, global_transformation: global_transformation)
      end

      if speckle_schema['method'] == 'Floor'
        return SpeckleObjects::BuiltElements::RevitFloor
               .to_speckle_schema(speckle_state, entity, units, global_transformation: global_transformation)
      end

      if speckle_schema['method'] == 'Default Wall'
        return SpeckleObjects::BuiltElements::DefaultWall
               .to_speckle_schema(entity, units, global_transformation: global_transformation)
      end

      if speckle_schema['method'] == 'Wall'
        return SpeckleObjects::BuiltElements::RevitWall
               .to_speckle_schema(speckle_state, entity, units, global_transformation: global_transformation)
      end

      return speckle_schema
    end
  end
end
