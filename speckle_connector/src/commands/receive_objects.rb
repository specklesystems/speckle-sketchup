# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/receive_objects'

module SpeckleConnector
  module Commands
    # Command to receive objects from Speckle Server.
    class ReceiveObjects < Command
      def _run(data)
        stream_id = data['stream_id']
        base = data['base']
        action = Actions::ReceiveObjects.new(stream_id, base)
        app.update_state!(action)
      end
    end
  end
end
