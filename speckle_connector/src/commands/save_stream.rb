# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../actions/save_stream'
require_relative '../actions/load_saved_streams'

module SpeckleConnector
  module Commands
    # Command to saved stream.
    class SaveStream < Command
      def _run(data)
        stream_id = data['stream_id']
        action = Actions::SaveStream.new(stream_id)
        app.update_state!(action)
        app.update_state!(Actions::LoadSavedStreams)
      end
    end
  end
end
