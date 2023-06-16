# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../callbacks/callback_message'
require_relative '../speckle_entities/speckle_entity'
require_relative '../mapper/mapper_source'

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleMapperState
      include Immutable::ImmutableUtils

      # @return [ImmutableHash{Integer=>Sketchup::Entity}] persistent_id of the sketchup entity and itself
      attr_reader :mapped_entities

      # @return [Mapper::MapperSource] source of the mapper.
      attr_reader :mapper_source

      def initialize
        @mapped_entities = Immutable::EmptyHash
        @mapper_source = nil
      end

      def with_mapped_entity(entity)
        new_mapped_entities = mapped_entities.put(entity.persistent_id, entity)
        with_mapped_entities(new_mapped_entities)
      end

      def with_removed_mapped_entity(entity)
        new_mapped_entities = mapped_entities.delete(entity.persistent_id)
        with_mapped_entities(new_mapped_entities)
      end

      def with_mapped_entities(new_mapped_entities)
        with(:@mapped_entities => new_mapped_entities)
      end

      def with_mapper_source(mapper_source)
        with(:@mapper_source => mapper_source)
      end
    end
  end
end
