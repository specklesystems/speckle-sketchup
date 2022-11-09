
module SpeckleConnector
  module Actions
    class Connected < Action
      def self.update_state(state)
        puts 'Speckle connected!'
        # TODO: Use here immutable ways to create new state from old one!
        States::State.new(state.user_state, state.speckle_state, true)
      end
    end
  end
end
