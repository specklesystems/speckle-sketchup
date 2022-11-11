# frozen_string_literal: true

module SpeckleConnector
  module States
    # Initial state of the application.
    class InitialState
      # @return [UserState] the user specific part of the states
      attr_reader :user_state

      # @return [Boolean] application is connector to server or not
      attr_reader :is_connected

      def initialize(user_state)
        @user_state = user_state
        @is_connected = false
        freeze
      end

      def speckle_state?
        false
      end
    end
  end
end
