# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'

module SpeckleConnector
  module Actions
    # Send already converted objects from queue if exist on stream.
    class SendFromQueue < Action
      def self.update_state(state, stream_id, dialog)
        to_send_stream_id = state.speckle_state.to_send[:stream_id]
        return state if to_send_stream_id == stream_id

        to_send_converted = state.speckle_state.to_send[:converted].to_json
        dialog.execute_script("convertedFromSketchup('#{to_send_stream_id}',#{to_send_converted})")
        dialog.execute_script("oneClickSend('#{to_send_converted}')")
        state
      end
    end
  end
end
