# frozen_string_literal: true

require_relative 'command_data'

module SpeckleConnector3
  module Ui
    # General purpose dialog to wrap {UI::HTMLDialog}.
    class Dialog
      DIALOG_READY = :dialog_ready
      DEFAULT_SPECS = {
        height: 400, width: 600, min_width: 250, min_height: 50
      }.freeze

      # @return bindings [Hash{String=>Ui::Binding}] views that responsible to run upcoming commands
      attr_reader :bindings

      # @param specs [Hash] the specifications that will be passed to {UI::HTMLDialog}
      def initialize(dialog_id:, htm_file:, **specs)
        @bindings = {}
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

      def reset_dialog_location
        html_dialog.center
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
        File.exist?(@htm_file) ? dialog.set_file(@htm_file) : dialog.set_url('http://localhost:8081')
        # dialog.set_url('http://localhost:8081') # uncomment this line if you want to use your local version of ui
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
          puts '### COMMAND CALLED BY DIALOG ###'
          puts "name: #{cmd.name}"
          @ready = true if cmd.name == DIALOG_READY
          # We have single view for legacy UI
          @bindings[SPECKLE_LEGACY_BINDING_NAME].commands[cmd.name].run(cmd.resolve_id, cmd.data)
        end
      end
    end
  end
end
