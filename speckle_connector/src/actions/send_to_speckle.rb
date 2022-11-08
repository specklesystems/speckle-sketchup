# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Sends to speckle.
    class SendToSpeckle < Action
      # @param state [States::State] the current state of Speckle
      # @param parameters [Array] parameters that the action takes
      # @return [States::State] the new updated state object
      def self.update_state(state, *parameters)
        puts 'send to speckle'
        state
      end
    end
  end
end
