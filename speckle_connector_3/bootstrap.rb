# frozen_string_literal: true

require 'sketchup'
require 'pathname'
require 'speckle_connector_3/debug'
require_relative 'src/log/log'
require_relative 'src/ui/sketchup_ui'
require_relative 'src/ui/ui_controller'
require_relative 'src/commands/menu_command_handler'
require_relative 'src/app/speckle_connector_app'
require_relative 'src/states/user_state'
require_relative 'src/states/initial_state'
require_relative 'src/commands/speckle_menu_commands'

# Speckle Connector on SketchUp to enable Multiplayer mode ON!
module SpeckleConnector3
  SKETCHUP_VERSION = Sketchup.version.to_i

  dir = __dir__.dup
  dir.force_encoding('UTF-8') if dir.respond_to?(:force_encoding)
  SPECKLE_CONNECTOR_SRC_PATH = Pathname.new(File.expand_path(dir)).cleanpath.to_s

  def self.initialize_app
    sketchup_ui = Ui::SketchupUi.new
    ui_controller = Ui::UiController.new(sketchup_ui)
    menu_commands = Commands::MenuCommandHandler.new
    user_state = SpeckleConnector3::States::UserState.new({})
    initial_state = SpeckleConnector3::States::InitialState.new(user_state)
    app = SpeckleConnector3::App::SpeckleConnectorApp.new(menu_commands, initial_state, ui_controller)
    # Add menu commands to SketchUp and Speckle application
    Commands::SpeckleMenuCommands.add_initial_commands!(app)
    app
  end

  app = initialize_app
  SPECKLE_APP = app
end
