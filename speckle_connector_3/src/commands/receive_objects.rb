# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/receive_objects'

module SpeckleConnector3
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
        object_id = data['object_id']
        action = Actions::ReceiveObjects.new(stream_id, base, stream_name, branch_name, branch_id, source_app, object_id)
        app.update_state!(action)
      end
    end
  end
end
