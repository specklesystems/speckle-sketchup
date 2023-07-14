# frozen_string_literal: true

require_relative 'command_data'

module SpeckleConnector
  module Ui
    # DUI3 dialog to wrap {UI::HTMLDialog}.
    class DUI3Dialog
      DIALOG_READY = :dialog_ready
      DEFAULT_SPECS = {
        height: 400, width: 600, min_width: 250, min_height: 50
      }.freeze

      # @return views [Hash{String=>Ui::View}] views that responsible to run upcoming commands
      attr_reader :views

      # @param specs [Hash] the specifications that will be passed to {UI::HTMLDialog}
      def initialize(dialog_id:, htm_file: nil, **specs)
        @views = {}
        @id = dialog_id
        @htm_file = htm_file
        @dialog_specs = DEFAULT_SPECS.merge(
          dialog_title: 'SpeckleSketchUp',
          preferences_key: "speckle.systems.#{dialog_id}"
        ).merge(specs)
      end

      def update_views(state)
        views.each_value do |view|
          view.update_view(state)
        end
      end

      def ready?
        @ready
      end

      # Show dialog if it's not visible yet
      def show
        bring_to_front if html_dialog.visible?
        return if html_dialog.visible?

        # reset dialog only if it is marked ready, otherwise
        # add_exec_callback is triggered twice upon first initialization
        reset_dialog!
        html_dialog.show
      end

      # Close the dialog
      def close
        html_dialog.close if html_dialog.visible?
      end

      # Show dialog in front of other dialogs
      def bring_to_front
        html_dialog.bring_to_front
      end

      # @return [Boolean] whether the dialog is visible or not
      def visible?
        html_dialog.visible?
      end

      def execute_script(data)
        html_dialog.execute_script(data)
      end

      private

      # @return [UI::HtmlDialog] the Sketchup interface to dialog
      def html_dialog
        @html_dialog ||= init_dialog
      end

      # Resets current instance of the HTMLDialog.
      def reset_dialog!
        @html_dialog = nil
        @ready = nil
      end

      # Create a new HTMLDialog
      # @return [UI::HtmlDialog] the Sketchup interface to html dialog
      def init_dialog
        dialog = UI::HtmlDialog.new(@dialog_specs)
        dialog.set_can_close do
          true
        end
        # File.exist?(@htm_file) ? dialog.set_file(@htm_file) : dialog.set_url('http://localhost:9091')
        dialog.set_url('http://localhost:3003') # uncomment this line if you want to use your local version of ui
        add_exec_callback(dialog)
        dialog
      end

      # Add callbacks to the HTMLDialog
      def add_exec_callback(html_dialog)
        html_dialog.add_action_callback('exec') do |_, data|
          exec_callback(data)
        end

        html_dialog.add_action_callback('getCommands') do |_, data|
          get_commands(data)
        end
      end

      def get_commands(view_id)
        if @views[view_id]
          commands_string = JSON.generate(@views[view_id].commands.keys)
          html_dialog.execute_script("bindings.receiveCommandsAndInitializeBridge('#{commands_string}')")
        else
          puts "There is no registered binding named: #{view_id}"
          html_dialog.execute_script("bindings.rejectBindings('There is no registered binding named: #{view_id}')")
        end
      end

      # Method parses commands sent from javascript code in HTML dialog and calls
      # and passes that commands to the object that handles the commands.
      # @param data [Array, Hash] data that comes as json from HTMLDialog
      def exec_callback(data)
        commands = CommandParser.parse_commands(data)
        commands.each do |cmd|
          puts '### COMMAND CALLED BY DIALOG ###'
          puts "name: #{cmd.name}"
          @ready = true if cmd.name == DIALOG_READY
          @views[data['view_id']].commands[cmd.name].run(cmd.resolve_id, cmd.data)
        end
      end
    end
  end
end