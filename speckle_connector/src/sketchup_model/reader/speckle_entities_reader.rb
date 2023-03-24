# frozen_string_literal: true

require_relative '../../speckle_entities/speckle_entity'
require_relative '../../constants/dict_constants'

module SpeckleConnector
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Reader model for sketchup model.
    module Reader
      # Reader module for speckle entities.
      module SpeckleEntitiesReader
        # @param entities [Sketchup::Entities] entities to collect speckle entities.
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
      end
    end
  end
end
