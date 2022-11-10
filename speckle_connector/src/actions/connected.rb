# frozen_string_literal: true

module SpeckleConnector
  module Actions
    # Action to update connected state of application.
    class Connected < Action
      def self.update_state(state)
        puts 'Speckle connected!'
        # TODO: Use here immutable ways to create new state from the old one!
        States::State.new(state.user_state, state.speckle_state, true)
      end
    end
  end
end
