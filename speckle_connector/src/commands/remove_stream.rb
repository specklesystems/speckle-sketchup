# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/remove_stream'
require_relative '../actions/load_saved_streams'

module SpeckleConnector
  module Commands
    # Command to remove stream.
    class RemoveStream < Command
      def _run(_resolve_id, data)
        stream_id = data['stream_id']
        action = Actions::RemoveStream.new(stream_id)
        app.update_state!(action)
        app.update_state!(Actions::LoadSavedStreams)
      end
    end
  end
end
