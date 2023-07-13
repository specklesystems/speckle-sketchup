# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/get_commands'

module SpeckleConnector
  module Commands
    # Get commands.
    class GetCommands < Command
      def _run(_resolve_id, _data)
        # commands = app.ui_controller.user_interfaces.values.collect.each { |view| view.commands.keys }.flatten
        commands_by_view = app.ui_controller.user_interfaces.collect do |view_id, view|
          [view_id, view.commands.keys]
        end.to_h
        action = Actions::GetCommands.new(commands_by_view)
        app.update_state!(action)
      end
    end
  end
end
