# frozen_string_literal: true

module SpeckleConnector
  module Actions
    # Action to update connected state of application.
    class Connected < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        puts 'Speckle connected!'
        state.with(:@connected => true)
      end
    end
  end
end
