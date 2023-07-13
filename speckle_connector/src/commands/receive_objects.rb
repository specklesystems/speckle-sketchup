# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/receive_objects'

module SpeckleConnector
  module Commands
    # Command to receive objects from Speckle Server.
    class ReceiveObjects < Command
      def _run(_resolve_id, data)
        stream_id = data['stream_id']
        base = data['base']
        branch_name = data['branch_name']
        branch_id = data['branch_id']
        stream_name = data['stream_name']
        source_app = data['source_app']
        action = Actions::ReceiveObjects.new(stream_id, base, stream_name, branch_name, branch_id, source_app)
        app.update_state!(action)
      end
    end
  end
end
