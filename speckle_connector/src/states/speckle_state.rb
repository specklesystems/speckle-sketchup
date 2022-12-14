# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../callbacks/callback_message'

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleState
      include Immutable::ImmutableUtils

      # @return [ImmutableHash{Integer=>Object}]
      attr_reader :speckle_entities

      # @return [Array] accounts on appdata.
      attr_reader :accounts

      # @return [Hash] queue to send to server.
      attr_reader :message_queue

      # @return [Hash] stream queue to send to server.
      attr_reader :stream_queue

      def initialize(accounts, queue, stream_queue)
        @accounts = accounts
        @message_queue = queue
        @stream_queue = stream_queue
        @speckle_entities = Immutable::EmptyHash
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
        application_id = traversed_entity[:applicationId]
        new_speckle_entities = speckle_entities.put(application_id, traversed_entity)
        with(:@speckle_entities => new_speckle_entities)
      end
    end
  end
end
