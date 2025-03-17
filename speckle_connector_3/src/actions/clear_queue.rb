# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector3
  module Actions
    # Clear queue from state.
    class ClearQueue < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        new_speckle_state = state.speckle_state.with(:@message_queue => {})
        state.with(:@speckle_state => new_speckle_state)
      end
    end
  end
end
