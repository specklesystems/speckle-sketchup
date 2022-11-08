# frozen_string_literal: true

require_relative 'command_data'

module SpeckleConnector
  module Ui
    # General purpose dialog to wrap {UI::HTMLDialog}.
    class Dialog
      DIALOG_READY = :dialog_ready
      DEFAULT_SPECS = {
        height: 400, width: 600, min_width: 250, min_height: 50
      }.freeze

      # @param commands [Hash{Symbol=>Object}] commands that are sent from the HTMLDialog
      # @param specs [Hash] the specifications that will be passed to {UI::HTMLDialog}
      def initialize(commands:, dialog_id:, dialog_title:, htm_file:, **specs)
        @commands = commands
        @id = dialog_id
        @htm_file = htm_file
        @dialog_specs = DEFAULT_SPECS.merge(
          dialog_title: 'SpeckleSketchUp',
          preferences_key: "speckle.systems.#{dialog_id}"
        ).merge(specs)
      end

      def ready?
        @ready
      end

      # Show dialog if it's not visible yet
      def show
        return if html_dialog.visible?

        # reset dialog only if it is marked ready, otherwise
        # add_exec_callback is triggered twice upon first initialization
        reset_dialog! if @ready
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
        File.exist?(@htm_file) ? dialog.set_file(@htm_file) : dialog.set_url('http://localhost:8081')
        # ui.set_url('http://localhost:8081') # uncomment this line if you want to use your local built version of ui
        add_exec_callback(dialog)
        dialog
      end

      # Add callbacks to the HTMLDialog
      def add_exec_callback(html_dialog)
        html_dialog.add_action_callback('exec') do |_, data|
          exec_callback(data)
        end
      end

      # Method parses commands sent from javascript code in HTML dialog and calls
      # and passes that commands to the object that handles the commands.
      # @param data [Array, Hash] data that comes as json from HTMLDialog
      def exec_callback(data)
        commands = CommandParser.parse_commands(data)
        commands.each do |cmd|
          puts "name: #{cmd.name}, data: #{cmd.data}"
          @ready = true if cmd.name == DIALOG_READY
          @commands[cmd.name].run(cmd.data)
        end
      end
    end
  end
end
