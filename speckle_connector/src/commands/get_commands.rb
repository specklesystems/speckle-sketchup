# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/get_commands'

module SpeckleConnector
  module Commands
    # Get commands.
    class GetCommands < Command
      def _run(_resolve_id, _data)
        # view_to_get_commands = app.ui_controller.user_interfaces[view]
        # commands_by_view = view_to_get_commands.commands.keys
        view_command_names = view.commands.keys
        # commands_by_view = app.ui_controller.user_interfaces.collect do |id, view|
        #   [id, view.commands.keys]
        # end.to_h
        action = Actions::GetCommands.new(view_command_names)
        app.update_state!(action)
      end
    end
  end
end
