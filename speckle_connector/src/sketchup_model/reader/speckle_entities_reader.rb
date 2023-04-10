# frozen_string_literal: true

require_relative '../dictionary/speckle_schema_dictionary_handler'
require_relative '../../speckle_entities/speckle_entity'
require_relative '../../mapping/category/revit_category'
require_relative '../../constants/dict_constants'

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Reader model for sketchup model.
    module Reader
      # Reader module for speckle entities.
      module SpeckleEntitiesReader
        # @param entities [Sketchup::Entities] entities to collect speckle entities.
        # @return [Hash{String=>Sketchup::Entity}] speckle entities with persistent id.
        def self.read(entities)
          speckle_entities = {}
          entities.each do |entity|
            speckle_entities[entity.persistent_id] = read_speckle_entity(entity) if speckle_entity?(entity)
            next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

            if speckle_entity?(entity.definition)
              speckle_entities[entity.definition.persistent_id] = read_speckle_entity(entity.definition)
            end
            definition_speckle_entities = read(entity.definition.entities)
            speckle_entities = speckle_entities.merge(definition_speckle_entities)
          end
          speckle_entities
        end

        # @param entities [Sketchup::Entities] entities to collect mapped entities.
        # @return [Hash{String=>Sketchup::Entity}] mapped entities with persistent id.
        def self.read_mapped_entities(entities)
          mapped_entities = {}
          Query::Entity.flat_entities(entities).each do |entity|
            mapped_entities[entity.persistent_id] = entity if mapped_with_schema?(entity)
          end
          mapped_entities
        end

        # @param entity [Sketchup::Entity] sketchup entity to read from attribute dictionary.
        def self.read_speckle_entity(entity)
          dict = entity.attribute_dictionaries.to_a.find { |d| d.name == SPECKLE_BASE_OBJECT }
          speckle_id = dict[:speckle_id]
          application_id = dict[:application_id]
          speckle_type = dict[:speckle_type]
          children = dict[:children]
          valid_stream_ids = dict[:valid_stream_ids]
          invalid_stream_ids = dict[:invalid_stream_ids]
          SpeckleEntities::SpeckleEntity.new(entity, speckle_id, application_id, speckle_type, children,
                                             valid_stream_ids, invalid_stream_ids)
        end

        # @param entity [Sketchup::Entity] sketchup entity to check if it was speckle entity once.
        def self.speckle_entity?(entity)
          return false if entity.attribute_dictionaries.nil?
          return false if entity.attribute_dictionaries.to_a.empty?

          entity.attribute_dictionaries.to_a.any? { |dict| dict.name == SPECKLE_BASE_OBJECT }
        end

        # @param entity [Sketchup::Entity] sketchup entity to check whether mapped with speckle schema or not.
        def self.mapped_with_schema?(entity)
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
              entity_selection_details = entity_selection_details.merge({ definition: entity_selection_details(entity.definition) })
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
          reverse_category_dictionary = Mapping::Category::RevitCategory.reverse_dictionary
          entities.collect do |entity|
            speckle_schema = get_schema(entity)
            {
              name: speckle_schema['name'],
              category: speckle_schema['category'],
              categoryName: reverse_category_dictionary[speckle_schema['category']],
              method: speckle_schema['method'],
              entityName: entity.respond_to?(:name) ? entity.name : '',
              entityId: entity.persistent_id,
              entityType: entity.class.name.split('::').last.gsub(/(?<=[a-z])(?=[A-Z])/, ' ').split.first,
              schema: speckle_schema,
              definitionSchema: entity.respond_to?(:definition) ? get_schema(entity.definition) : nil
            }
          end
        end
      end
    end
  end
end
