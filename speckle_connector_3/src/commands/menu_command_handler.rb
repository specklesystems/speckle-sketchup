# frozen_string_literal: true

module SpeckleConnector3
  module Commands
    # Helper class to register, handle menu and toolbar commands.
    class MenuCommandHandler
      # @param command [#run] command that can be run
      # @param menu_text [String] name of the command that will be displayed on the menu
      # @return [UI::Command] the command that can be added to Sketchup menu or toolbar
      def self.sketchup_command(command, menu_text)
        UI::Command.new(menu_text) do
          command.run
        end
      end

      # Validate if the user has started the Speckle and return a status code that can be used by
      # {UI::Command#set_validation_proc} to disable menu entries and toolbar entries before Speckle is loaded.
      def self.speckle_started(app)
        return MF_ENABLED if app.speckle_loaded?

        MF_GRAYED
      end

      def initialize
        @menu_commands = {}
        @added_to_menu = []
        @added_to_toolbar = []
      end

      def []=(command_id, command)
        @menu_commands[command_id] = command
      end

      # Add command to menu.
      def add_to_menu!(command_id, menu)
        return if @added_to_menu.include? command_id

        menu.add_item(@menu_commands[command_id])
        @added_to_menu << command_id
      end

      # Add command to toolbar.
      def add_to_toolbar!(command_id, toolbar)
        return if @added_to_toolbar.include? command_id

        toolbar.add_item(@menu_commands[command_id])
        @added_to_toolbar << command_id
      end
    end
  end
end
