# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/activate_diffing'

module SpeckleConnector
  module Commands
    # Command to activate diffing for stream.
    class ActivateDiffing < Command
      def _run(data)
        stream_id = data['stream_id']
        action = Actions::ActivateDiffing.new(stream_id)
        app.update_state!(action)
      end
    end
  end
end
