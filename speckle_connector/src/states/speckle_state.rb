# frozen_string_literal: true

require_relative 'speckle_mapper_state'
require_relative '../immutable/immutable'
require_relative '../callbacks/callback_message'
require_relative '../speckle_entities/speckle_entity'

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleState
      include Immutable::ImmutableUtils

      # @return [States::SpeckleMapperState] state of the mapper.
      attr_reader :speckle_mapper_state

      # @return [ImmutableHash{Integer=>SpeckleEntities::SpeckleEntity}] persistent_id of the sketchup entity and
      #  corresponding speckle entity
      attr_reader :speckle_entities

      # @return [Array] accounts on appdata.
      attr_reader :accounts

      # @return [Hash{Class => Observer}] the observer objects that are used to attach to objects in Sketchup to collect
      #  events that are triggered from Sketchup
      attr_reader :observers

      # @return [Hash] queue to send to server.
      attr_reader :message_queue

      # @return [Hash] stream queue to send to server.
      attr_reader :stream_queue

      # @return [Relations::ManyToOneRelation] relations between objects.
      attr_accessor :relation

      # TODO: Do cashing later
      # @return [ImmutableHash{String=>SpeckleObjects::Other::RenderMaterial}] converted render materials
      attr_accessor :render_materials

      # TODO: Do cashing later
      # @return [ImmutableHash{String=>SpeckleObjects::Other::BlockDefinition}] converted component definitions
      attr_accessor :definitions

      def initialize(accounts, observers, queue, stream_queue)
        @accounts = accounts
        @observers = observers
        @message_queue = queue
        @stream_queue = stream_queue
        @speckle_entities = Immutable::EmptyHash
        @render_materials = Immutable::EmptyHash
        @definitions = Immutable::EmptyHash
        @relation = Relations::ManyToOneRelation.new
        @speckle_mapper_state = SpeckleMapperState.new
      end

      # @param callback_name [String] name of the callback command
      # @param stream_id [String] id of the stream
      # @param parameters [Array<String>] parameters of the callback method call
      def with_add_queue(callback_name, stream_id, parameters)
        next_queue_message = Callbacks::CallbackMessage.serialize(callback_name, stream_id, parameters)
        new_queue = message_queue.merge({ "#{callback_name}": next_queue_message })
        with(:@message_queue => new_queue)
      end

      def with_mapped_entities_queue(mapped_entities)
        new_queue = message_queue.merge({ "mappedEntitiesUpdated":
                                            "mappedEntitiesUpdated(#{JSON.generate(mapped_entities)})" })
        with(:@message_queue => new_queue)
      end

      def with_mapper_selection_queue(selection_parameters)
        new_queue = message_queue.merge({ "entitySelected":
                                            "entitySelected(#{JSON.generate(selection_parameters)})" })
        with(:@message_queue => new_queue)
      end

      def with_mapper_init_queue(init_parameters)
        new_queue = message_queue.merge({ "mapperInitialized":
                                            "mapperInitialized(#{JSON.generate(init_parameters)})" })
        with(:@message_queue => new_queue)
      end

      def with_mapper_deselection_queue
        new_queue = message_queue.merge({ "entitiesDeselected": 'entitiesDeselected()' })
        with(:@message_queue => new_queue)
      end

      def with_invalid_streams_queue
        new_queue = message_queue.merge({ "updateInvalidStreams":
                                            "updateInvalidStreams(#{JSON.generate(invalid_streams)})" })
        with(:@message_queue => new_queue)
      end

      def with_empty_invalid_streams_queue
        new_queue = message_queue.merge({ "updateInvalidStreams":
                                            "updateInvalidStreams(#{JSON.generate([])})" })
        with(:@message_queue => new_queue)
      end

      def with_accounts(new_accounts)
        with(:@accounts => new_accounts)
      end

      def with_mapper_source(mapper_source)
        new_speckle_mapper_state = speckle_mapper_state.with_mapper_source(mapper_source)
        with(:@speckle_mapper_state => new_speckle_mapper_state)
      end

      def with_removed_mapper_source
        new_speckle_mapper_state = speckle_mapper_state.with_mapper_source(nil)
        with(:@speckle_mapper_state => new_speckle_mapper_state)
      end

      def with_mapped_entity(entity)
        new_speckle_mapper_state = speckle_mapper_state.with_mapped_entity(entity)
        with(:@speckle_mapper_state => new_speckle_mapper_state)
      end

      def with_removed_mapped_entity(entity)
        new_speckle_mapper_state = speckle_mapper_state.with_removed_mapped_entity(entity)
        with(:@speckle_mapper_state => new_speckle_mapper_state)
      end

      def with_mapped_entities(new_mapped_entities)
        new_speckle_mapper_state = speckle_mapper_state.with_mapped_entities(new_mapped_entities)
        with(:@speckle_mapper_state => new_speckle_mapper_state)
      end

      def with_speckle_entity(traversed_entity)
        new_speckle_entities = speckle_entities.put(traversed_entity.application_id, traversed_entity)
        with_speckle_entities(new_speckle_entities)
      end

      def with_speckle_entities(new_speckle_entities)
        with(:@speckle_entities => new_speckle_entities)
      end

      def with_relation(new_relation)
        with(:@relation => new_relation)
      end

      def invalid_streams
        speckle_entities.collect do |_id, speckle_entity|
          speckle_entity.invalid_stream_ids
        end.reduce([], :concat).uniq
      end
    end
  end
end
