# frozen_string_literal: true

module SpeckleConnector
  module States
    class InitialState
      # @return [UserState] the user specific part of the states
      attr_reader :user_state

      def initialize(user_state)
        @user_state = user_state
        freeze
      end
    end
  end
end
