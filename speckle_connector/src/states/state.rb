# frozen_string_literal: true

module SpeckleConnector
  module States
    # State of the application.
    class State < InitialState
      # @return [SpeckleState] the states of the Speckle
      attr_reader :speckle_state

      # @return [UserState] the user specific part of the states
      attr_reader :user_state

      def initialize(user_state, speckle_state, is_connected)
        @speckle_state = speckle_state
        @is_connected = is_connected
        super(user_state)
      end

      def speckle_state?
        true
      end
    end
  end
end
