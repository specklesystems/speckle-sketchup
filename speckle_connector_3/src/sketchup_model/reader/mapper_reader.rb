# frozen_string_literal: true

require_relative '../dictionary/speckle_schema_dictionary_handler'
require_relative '../../speckle_entities/speckle_entity'
require_relative '../../mapper/category/revit_category'
require_relative '../../constants/dict_constants'

module SpeckleConnector3
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Reader model for sketchup model.
    module Reader
      # Reader module for mapper.
      module MapperReader
        # @param entities [Sketchup::Entities] entities to collect mapped entities.
        # @return [Hash{String=>Sketchup::Entity}] mapped entities with persistent id.
        def self.read_mapped_entities(entities)
          mapped_entities = {}
          Query::Entity.flat_entities(entities).each do |entity|
            mapped_entities[entity.persistent_id] = entity if mapped_with_schema?(entity)
          end
          mapped_entities
        end

        # @param entity [Sketchup::Entity] sketchup entity to check whether mapped with speckle schema or not.
        def self.mapped_with_schema?(entity)
          # We do not necessarily consider grouped meshes for mappings
          return false if entity.is_a?(SpeckleObjects::Geometry::GroupedMesh)

          is_entity_mapped = !Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity).nil?
          return is_entity_mapped if is_entity_mapped
          return is_entity_mapped unless entity.is_a?(Sketchup::ComponentInstance)

          !Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(entity.definition).nil?
        end

        def self.get_schema(entity)
          Dictionary::SpeckleSchemaDictionaryHandler.speckle_schema_to_speckle(entity)
        end

        def self.entities_schema_details(entities)
          entities.collect do |entity|
            entity_selection_details = entity_selection_details(entity)
            if entity.is_a?(Sketchup::ComponentInstance)
              entity_selection_details = entity_selection_details.merge(
                { definition: entity_selection_details(entity.definition) }
              )
            end
            entity_selection_details
          end
        end

        def self.entity_selection_details(entity)
          sanitized_type = entity.class.name.split('::').last.gsub(/(?<=[a-z])(?=[A-Z])/, ' ').split
          is_definition = entity.is_a?(Sketchup::ComponentDefinition)
          entity_type = is_definition ? sanitized_type.last : sanitized_type.first
          speckle_schema = get_schema(entity)
          {
            name: speckle_schema['name'],
            entityName: entity.respond_to?(:name) ? entity.name : '',
            entityId: entity.persistent_id,
            entityType: entity_type,
            schema: speckle_schema,
            numberOfInstances: is_definition ? entity.instances.length : 1
          }
        end

        def self.mapped_entity_details(entities)
          reverse_category_dictionary = Mapper::Category::RevitCategory.reverse_dictionary
          entities.collect do |entity|
            speckle_schema = get_schema(entity)
            speckle_schema_definition = entity.respond_to?(:definition) ? get_schema(entity.definition) : nil
            entity_type = entity.class.name.split('::').last.gsub(/(?<=[a-z])(?=[A-Z])/, ' ').split.first
            category = get_map_attribute(speckle_schema, speckle_schema_definition, 'category')
            {
              name: get_map_attribute(speckle_schema, speckle_schema_definition, 'name'),
              category: category,
              categoryName: category.nil? ? '' : reverse_category_dictionary[category],
              method: get_map_attribute(speckle_schema, speckle_schema_definition, 'method'),
              entityName: entity.respond_to?(:name) ? entity.name : '',
              entityId: entity.persistent_id,
              entityType: entity.is_a?(Sketchup::ComponentDefinition) ? 'Definition' : entity_type,
              schema: speckle_schema,
              definitionSchema: speckle_schema_definition
            }
          end
        end

        def self.get_map_attribute(schema, definition_schema, attribute)
          return schema[attribute] if schema[attribute]
          return definition_schema[attribute] if !definition_schema.nil? && definition_schema[attribute]

          nil
        end
      end
    end
  end
end
