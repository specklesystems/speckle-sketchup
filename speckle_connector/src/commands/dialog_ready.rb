# frozen_string_literal: true

require_relative 'command'

module SpeckleConnector
  module Commands
    # Run this command when the UI is ready to get data
    class DialogReady < Command
      # Update the selected user interface
      def _run(_data)
        view.update_view(app.state)
      end
    end
  end
end
