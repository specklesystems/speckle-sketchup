# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

module SpeckleConnector
  module Commands
    # Command to notify connected.
    class NotifyConnected < Command
      def _run(data)
        stream_id = data['stream_id']
        app.update_state!(Actions::Connected)
        app.update_state!(Actions::SendFromQueue, stream_id, view.dialog)
      end
    end
  end
end
