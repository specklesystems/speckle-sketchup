# frozen_string_literal: true

require_relative '../immutable/immutable'

module SpeckleConnector
  module States
    # State of the application.
    class State < InitialState
      include Immutable::ImmutableUtils

      # @return [States::SketchupState] the state of the Sketchup Application
      attr_reader :sketchup_state

      # @return [States::SpeckleState] the states of the Speckle
      attr_reader :speckle_state

      # @return [States::UserState] the user specific part of the states
      attr_reader :user_state

      def initialize(user_state, speckle_state, sketchup_state, is_connected)
        @speckle_state = speckle_state
        @is_connected = is_connected
        @sketchup_state = sketchup_state
        super(user_state)
      end

      def speckle_state?
        true
      end

      # @param callback_name [String] name of the callback command
      # @param stream_id [String] id of the stream
      # @param parameters [Array<String>] parameters of the callback method call
      def with_add_queue(callback_name, stream_id, parameters)
        new_speckle_state = speckle_state.with_add_queue(callback_name, stream_id, parameters)
        with(:@speckle_state => new_speckle_state)
      end

      def with_empty_stream_queue
        new_speckle_state = speckle_state.with(:@stream_queue => {})
        with(:@speckle_state => new_speckle_state)
      end
    end
  end
end
