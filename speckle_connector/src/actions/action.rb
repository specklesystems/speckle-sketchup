# frozen_string_literal: true

module SpeckleConnector
  module Actions
    # State changer object.
    class Action
      # @param state [States::State] the current state of Speckle
      # @param parameters [Array] parameters that the action takes
      # @return [States::State] the new updated state object
      def self.update_state(state, *parameters)
        raise NotImplementedError, 'Implement in subclass.'
      end
    end
  end
end
