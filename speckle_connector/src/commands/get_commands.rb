# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/get_commands'

module SpeckleConnector
  module Commands
    # Get commands.
    class GetCommands < Command
      def _run(_resolve_id, _data)
        commands = app.ui_controller.user_interfaces.values.collect.each { |view| view.commands.keys }.flatten
        action = Actions::GetCommands.new(commands)
        app.update_state!(action)
      end
    end
  end
end
