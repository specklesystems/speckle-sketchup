# frozen_string_literal: true

require_relative '../speckle_objects/built_elements/revit/revit_floor'
require_relative '../speckle_objects/built_elements/revit/revit_wall'
require_relative '../speckle_objects/built_elements/revit/direct_shape'
require_relative '../speckle_objects/built_elements/revit/revit_column'
require_relative '../speckle_objects/built_elements/revit/revit_beam'
require_relative '../speckle_objects/built_elements/revit/revit_pipe'
require_relative '../speckle_objects/built_elements/revit/revit_duct'
require_relative '../speckle_objects/built_elements/default_floor'
require_relative '../speckle_objects/built_elements/default_wall'
require_relative '../speckle_objects/built_elements/default_column'
require_relative '../speckle_objects/built_elements/default_beam'
require_relative '../speckle_objects/built_elements/default_duct'
require_relative '../speckle_objects/built_elements/default_pipe'
require_relative '../speckle_objects/other/mapped_block_wrapper'
require_relative '../sketchup_model/query/entity'
require_relative '../sketchup_model/reader/mapper_reader'
require_relative '../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  # Mapper is a tool to convert SketchUp entities to other applications' native objects.
  module Mapper
    QUERY = SketchupModel::Query
    MAPPER_READER = SketchupModel::Reader::MapperReader
    SPECKLE_SCHEMA_DICTIONARY_HANDLER = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler
    DIRECT_SHAPE = SpeckleObjects::BuiltElements::Revit::DirectShape

    # Collects mapped entities on selection as flat list.
    def self.mapped_entities_on_selection(sketchup_model)
      flat_selection_with_path = QUERY::Entity.flat_entities_with_path(
        sketchup_model.selection,
        [Sketchup::Edge, Sketchup::Face, Sketchup::ComponentInstance, Sketchup::Group], [sketchup_model]
      )
      mapped_selection = []
      flat_selection_with_path.each do |entities|
        entity = entities[0]
        is_entity_mapped = MAPPER_READER.mapped_with_schema?(entity)
        if entity.respond_to?(:definition)
          is_definition_mapped = MAPPER_READER.mapped_with_schema?(entity.definition)
          mapped_selection.append(entities) if is_entity_mapped || is_definition_mapped
          next
        end
        mapped_selection.append(entities) if is_entity_mapped
      end
      mapped_selection
    end

    def self.convert_mapped_entity(speckle_state, entity_with_path, preferences, units, &convert)
      entity = entity_with_path[0]
      method = get_method(entity)
      return nil if method.nil?

      path = entity_with_path[1..-1]

      if face_mapping?(entity, method)
        global_transformation = QUERY::Entity.global_transformation(entity, path)
        face = SpeckleObjects::Geometry::Mesh.from_face(speckle_state: speckle_state, face: entity,
                                                        units: units, model_preferences: preferences,
                                                        global_transform: global_transformation)
        return [face, [entity]]
      end

      if edge_mapping?(entity, method)
        global_transformation = QUERY::Entity.global_transformation(entity, path)
        edge = SpeckleObjects::Geometry::Line.from_edge(speckle_state: speckle_state, edge: entity,
                                                        units: units, model_preferences: preferences,
                                                        global_transformation: global_transformation)
        return [edge, [entity]]
      end

      if method == 'Direct Shape'
        direct_shape = DIRECT_SHAPE.from_entity(speckle_state, entity, path, units, preferences)
        return [direct_shape, [entity]]
      end

      if ['New Revit Family', 'Family Instance'].include?(method)
        _speckle_state, block_instance = SpeckleObjects::Other::BlockInstance.from_component_instance(
          entity, units, preferences, speckle_state, path: path, &convert
        )
        return [block_instance, [entity]]
      end

      nil
    end

    NATIVE_MAPPING_TO_SPECKLE = {
      'Default Column' => SpeckleObjects::BuiltElements::DefaultColumn.method(:to_speckle_schema),
      'Default Beam' => SpeckleObjects::BuiltElements::DefaultBeam.method(:to_speckle_schema),
      'Default Pipe' => SpeckleObjects::BuiltElements::DefaultPipe.method(:to_speckle_schema),
      'Default Duct' => SpeckleObjects::BuiltElements::DefaultDuct.method(:to_speckle_schema),
      'Column' => SpeckleObjects::BuiltElements::RevitColumn.method(:to_speckle_schema),
      'Beam' => SpeckleObjects::BuiltElements::RevitBeam.method(:to_speckle_schema),
      'Pipe' => SpeckleObjects::BuiltElements::RevitPipe.method(:to_speckle_schema),
      'Duct' => SpeckleObjects::BuiltElements::RevitDuct.method(:to_speckle_schema)
    }.freeze

    def self.to_speckle(speckle_state, entity, units, global_transformation: nil)
      speckle_schema = SPECKLE_SCHEMA_DICTIONARY_HANDLER.speckle_schema_to_speckle(entity)
      return speckle_schema if speckle_schema.nil?

      to_speckle_schema_method = NATIVE_MAPPING_TO_SPECKLE[speckle_schema['method']]
      return speckle_schema if to_speckle_schema_method.nil?

      to_speckle_schema_method.call(speckle_state, entity, units, global_transformation: global_transformation)
    end

    def self.get_method(entity)
      method = SPECKLE_SCHEMA_DICTIONARY_HANDLER.get_attribute(entity, 'method')
      return method if method

      if entity.is_a?(Sketchup::ComponentInstance)
        method = SPECKLE_SCHEMA_DICTIONARY_HANDLER.get_attribute(entity.definition, 'method')
      end
      method
    end

    def self.face_mapping?(entity, method)
      (method.include?('Floor') || method.include?('Wall')) && entity.is_a?(Sketchup::Face)
    end

    def self.edge_mapping?(entity, method)
      (method.include?('Column') || method.include?('Beam') || method.include?('Pipe') || method.include?('Duct')) &&
        entity.is_a?(Sketchup::Edge)
    end
  end
end
