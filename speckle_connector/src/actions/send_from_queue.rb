# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'

module SpeckleConnector
  module Actions
    # Send already converted objects from queue if exist on stream.
    class SendFromQueue < Action
      def initialize(stream_id)
        super()
        @stream_id = stream_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        to_send_stream_id = state.speckle_state.stream_queue[:stream_id]
        return state if to_send_stream_id == @stream_id || to_send_stream_id.nil?

        to_send_converted = state.speckle_state.stream_queue[:converted].to_json
        new_state = state.with_add_queue('convertedFromSketchup', to_send_stream_id, [to_send_converted])
        new_state.with_empty_stream_queue
      end
    end
  end
end
