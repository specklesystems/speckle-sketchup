# frozen_string_literal: true

require_relative 'menu_command_handler'
require_relative 'action_command'
require_relative 'initialize_speckle'
require_relative 'reset_window_location'
require_relative 'initialize_dui3_speckle'

module SpeckleConnector3
  module Commands
    # Speckle menu commands that adds them to Sketchup menu and toolbar.
    class SpeckleMenuCommands
      CMD_INITIALIZE_SPECKLE = :initialize_speckle
      CMD_RESET_WINDOW_LOCATION_SPECKLE = :reset_window_location_speckle
      CMD_INITIALIZE_DUI3_SPECKLE = :initialize_dui3_speckle
      CMD_SEND_TO_SPECKLE = :send_to_speckle
      CMD_RECEIVE_FROM_SPECKLE = :receive_from_speckle

      # Add initial set of commands to Speckle application object and to Sketchup menu and toolbar
      # @param app [App::SpeckleConnectorApp] the application object
      def self.add_initial_commands!(app)
        commands = app.menu_commands
        ui_controller = app.ui_controller
        sketchup_ui = ui_controller.sketchup_ui
        speckle_menu = sketchup_ui.speckle_menu
        speckle_toolbar = sketchup_ui.speckle_toolbar

        # commands[CMD_INITIALIZE_SPECKLE] = initialize_speckle_command(app)
        # commands.add_to_menu!(CMD_INITIALIZE_SPECKLE, speckle_menu)
        # commands.add_to_toolbar!(CMD_INITIALIZE_SPECKLE, speckle_toolbar)

        commands[CMD_RESET_WINDOW_LOCATION_SPECKLE] = reset_window_location_command(app)
        commands.add_to_menu!(CMD_RESET_WINDOW_LOCATION_SPECKLE, speckle_menu)

        commands[CMD_INITIALIZE_DUI3_SPECKLE] = initialize_dui3_speckle_command(app)
        commands.add_to_menu!(CMD_INITIALIZE_DUI3_SPECKLE, speckle_menu)
        commands.add_to_toolbar!(CMD_INITIALIZE_DUI3_SPECKLE, speckle_toolbar)

        # commands[CMD_SEND_TO_SPECKLE] = send_command(app)
        # commands.add_to_menu!(CMD_SEND_TO_SPECKLE, speckle_menu)
        # commands.add_to_toolbar!(CMD_SEND_TO_SPECKLE, speckle_toolbar)
      end

      def self.initialize_speckle_command(app)
        cmd = MenuCommandHandler.sketchup_command(
          InitializeSpeckle.new(app, nil), 'Initialize Speckle'
        )
        cmd.tooltip = 'Launch Connector'
        cmd.status_bar_text = 'Opens the Speckle Connector window'
        cmd.small_icon  = '../../img/s2logo.png'
        cmd.large_icon  = '../../img/s2logo.png'
        cmd
      end

      def self.reset_window_location_command(app)
        cmd = MenuCommandHandler.sketchup_command(
          ResetWindowLocation.new(app, nil), 'Reset Window Location'
        )
        cmd.tooltip = 'Bring Speckle window onto center of SketchUp window'
        cmd.status_bar_text = 'Bring Speckle window onto center of SketchUp window'
        cmd.small_icon  = '../../img/s2logo.png'
        cmd.large_icon  = '../../img/s2logo.png'
        cmd
      end

      def self.initialize_dui3_speckle_command(app)
        cmd = MenuCommandHandler.sketchup_command(
          InitializeDUI3Speckle.new(app, nil), 'Initialize Speckle (Beta)'
        )
        cmd.tooltip = 'Speckle (Beta) for SketchUp'
        cmd.status_bar_text = 'Opens the Speckle Connector (Beta)'
        cmd.small_icon  = '../../img/s2logo_dui3.png'
        cmd.large_icon  = '../../img/s2logo_dui3.png'
        cmd
      end

      def self.send_command(app)
        cmd = MenuCommandHandler.sketchup_command(
          ActionCommand.new(app, nil, Actions::OneClickSend), 'Send to Speckle'
        )
        cmd.tooltip = 'Send to Speckle'
        cmd.status_bar_text = 'Send to Speckle'
        cmd.small_icon = '../../img/Sender.png'
        cmd.large_icon = '../../img/Sender.png'
        cmd.set_validation_proc { MenuCommandHandler.speckle_started(app) }
        cmd
      end
    end
  end
end
