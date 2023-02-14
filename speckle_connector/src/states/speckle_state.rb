# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../callbacks/callback_message'

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleState
      include Immutable::ImmutableUtils

      # @return [ImmutableHash{Integer=>SpeckleBaseEntity}] persistent_id of the sketchup entity and corresponding
      #  speckle entity
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

      def initialize(accounts, observers, queue, stream_queue)
        @accounts = accounts
        @observers = observers
        @message_queue = queue
        @stream_queue = stream_queue
        @speckle_entities = Immutable::EmptyHash
        @relation = Relations::ManyToOneRelation.new
      end

      # @param callback_name [String] name of the callback command
      # @param stream_id [String] id of the stream
      # @param parameters [Array<String>] parameters of the callback method call
      def with_add_queue(callback_name, stream_id, parameters)
        next_queue_message = Callbacks::CallbackMessage.serialize(callback_name, stream_id, parameters)
        new_queue = message_queue.merge({ "#{callback_name}": next_queue_message })
        with(:@message_queue => new_queue)
      end

      def with_accounts(new_accounts)
        with(:@accounts => new_accounts)
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
    end
  end
end
