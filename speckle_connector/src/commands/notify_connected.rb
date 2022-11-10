# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/connected'
require_relative '../actions/send_from_queue'

module SpeckleConnector
  module Commands
    # Command to notify connected.
    class NotifyConnected < Command
      def _run(data)
        stream_id = data['stream_id']
        app.update_state!(Actions::Connected)
        app.update_state!(Actions::SendFromQueue.new(stream_id))
      end
    end
  end
end
