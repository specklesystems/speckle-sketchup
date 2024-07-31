# frozen_string_literal: true

require_relative 'action'
require_relative '../states/state'
require_relative '../states/speckle_state'
require_relative '../actions/send_from_queue'

module SpeckleConnector3
  module Actions
    # Send queue from state.
    class QueueSend < Action
      def initialize(stream_id, converted)
        super()
        @stream_id = stream_id
        @converted = converted
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        to_send = { stream_id: @stream_id, converted: @converted }
        new_speckle_state = state.speckle_state.with(:@stream_queue => to_send)
        new_state = state.with(:@speckle_state => new_speckle_state)
        if new_state.is_connected
          action = Actions::SendFromQueue.new(@stream_id)
          new_state = action.update_state(new_state)
        end
        new_state
      end
    end
  end
end
