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

      # @return [Immutable::Hash{String=>Cards::SendCard}] send cards.
      attr_reader :send_cards

      # @return [Immutable::Hash{String=>Cards::ReceiveCard}] receive cards.
      attr_reader :receive_cards

      # @return [Immutable::Hash{String=>Immutable::Hash{String=>SpeckleObjects::ObjectReference}}] object references that sent before server.
      attr_reader :object_references_by_project

      # @return [Immutable::Set] changed entity ids.
      attr_reader :changed_entity_persistent_ids

      # @return [Immutable::Set] changed entity ids.
      attr_reader :changed_entity_ids

      # @return [States::SpeckleMapperState] state of the mapper.
      attr_reader :speckle_mapper_state

      # @return [Immutable::Hash{Integer=>SpeckleEntities::SpeckleEntity}] persistent_id of the sketchup entity and
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
      # @return [Immutable::Hash{String=>SpeckleObjects::Other::RenderMaterial}] converted render materials
      attr_accessor :render_materials

      # TODO: Do cashing later
      # @return [Immutable::Hash{String=>SpeckleObjects::Other::BlockDefinition}] converted component definitions
      attr_accessor :definitions

      def initialize(accounts, observers, queue, stream_queue)
        @accounts = accounts
        @observers = observers
        @message_queue = queue
        @stream_queue = stream_queue
        @changed_entity_persistent_ids = Immutable::EmptySet
        @changed_entity_ids = Immutable::EmptySet
        @object_references_by_project = Immutable::EmptyHash
        @speckle_entities = Immutable::EmptyHash
        @render_materials = Immutable::EmptyHash
        @definitions = Immutable::EmptyHash
        @send_cards = Immutable::EmptyHash
        @receive_cards = Immutable::EmptyHash
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

      def with_add_queue_js_command(callback_name, js_command)
        new_queue = message_queue.merge("#{callback_name}": js_command)
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

      def with_send_card(send_card)
        new_send_cards = send_cards.put(send_card.model_card_id, send_card)
        with(:@send_cards => new_send_cards)
      end

      def without_send_card(id)
        new_send_cards = send_cards.delete(id)
        with(:@send_cards => new_send_cards)
      end

      def with_receive_card(receive_card)
        new_receive_cards = receive_cards.put(receive_card.model_card_id, receive_card)
        with(:@receive_cards => new_receive_cards)
      end

      def without_receive_card(id)
        new_receive_cards = receive_cards.delete(id)
        with(:@receive_cards => new_receive_cards)
      end

      def with_empty_changed_entity_persistent_ids
        with(:@changed_entity_persistent_ids => Immutable::EmptySet)
      end

      def with_changed_entity_persistent_ids(ids)
        new_ids = changed_entity_persistent_ids + Immutable::Set.new(ids)
        with(:@changed_entity_persistent_ids => new_ids)
      end

      def with_empty_changed_entity_ids
        with(:@changed_entity_ids => Immutable::EmptySet)
      end

      # POC: Not happy with it. We need to log also entity.entityID property since
      # onElementRemoved observer only return them! :/ Reconsider this in BETA!
      def with_changed_entity_ids(ids)
        new_ids = changed_entity_ids + Immutable::Set.new(ids)
        with(:@changed_entity_ids => new_ids)
      end

      def with_relation(new_relation)
        with(:@relation => new_relation)
      end

      def with_object_references(project_id, references)
        project_references = object_references_by_project[project_id] || Immutable::EmptyHash
        new_project_references = project_references
        references.each do |application_id, ref|
          new_project_references = new_project_references.put(application_id, ref)
        end
        with(:@object_references_by_project => object_references_by_project.put(project_id, new_project_references))
      end

      def invalid_streams
        speckle_entities.collect do |_id, speckle_entity|
          speckle_entity.invalid_stream_ids
        end.reduce([], :concat).uniq
      end
    end
  end
end
