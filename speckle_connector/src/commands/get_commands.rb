# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/get_commands'

module SpeckleConnector
  module Commands
    # Get commands.
    class GetCommands < Command
      def _run(_resolve_id, _data)
        view_command_names = view.commands.keys
        action = Actions::GetCommands.new(view_command_names)
        app.update_state!(action)
      end
    end
  end
end
