# frozen_string_literal: true

require_relative 'action'
require_relative '../states/state'
require_relative '../states/speckle_state'
require_relative '../accounts/accounts'
require_relative '../actions/send_from_queue'

module SpeckleConnector
  module Actions
    # Send queue from state.
    class QueueSend < Action
      def self.update_state(state, stream_id, converted, dialog)
        to_send = { stream_id: stream_id, converted: converted }
        new_speckle_state = States::SpeckleState.new(state.speckle_state.accounts, to_send)
        new_state = States::State.new(state.user_state, new_speckle_state, state.is_connected)
        new_state = Actions::SendFromQueue.update_state(new_state, stream_id, dialog) if state.is_connected
        new_state
      end
    end
  end
end
