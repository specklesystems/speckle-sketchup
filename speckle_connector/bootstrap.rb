# frozen_string_literal: true

require 'sketchup'
require 'pathname'
require 'speckle_connector/dialog'
require 'speckle_connector/debug'
require_relative 'src/ui/sketchup_ui'
require_relative 'src/ui/ui_controller'
require_relative 'src/commands/menu_command_handler'
require_relative 'src/app/speckle_connector_app'
require_relative 'src/app/e/user_state'
require_relative 'src/app/e/initial_state'

# Speckle Connector on SketchUp to enable Multiplayer mode ON!
module SpeckleConnector
  SKETCHUP_VERSION = Sketchup.version.to_i

  dir = __dir__.dup
  dir.force_encoding('UTF-8') if dir.respond_to?(:force_encoding)
  SPECKLE_CONNECTOR_SRC_PATH = Pathname.new(File.expand_path(dir)).cleanpath.to_s

  def self.initialize_app
    sketchup_ui = Ui::SketchupUi.new
    ui_controller = Ui::UiController.new(sketchup_ui)
    menu_commands = Commands::MenuCommandHandler.new
    user_state = SpeckleConnector::App::UserState.new({})
    initial_state = SpeckleConnector::App::InitialState.new(user_state)
    SpeckleConnector::App::SpeckleConnectorApp.new(menu_commands, initial_state, ui_controller)
  end

  app = initialize_app
  SPECKLE_APP = app

  unless file_loaded?(__FILE__)
    cmd_cube = UI::Command.new('Dialog') { create_dialog }
    cmd_cube.tooltip = 'Launch Connector'
    cmd_cube.status_bar_text = 'Opens the Speckle Connector window'
    cmd_cube.small_icon  = 'img/s2logo.png'
    cmd_cube.large_icon  = 'img/s2logo.png'

    menu = UI.menu('Tools')
    menu.add_item(cmd_cube)

    cmd_send = UI::Command.new('Send') { one_click_send }
    cmd_send.tooltip = 'Send to Speckle'
    cmd_send.status_bar_text = 'Send to Speckle'
    cmd_send.small_icon = 'img/Sender.png'
    cmd_send.large_icon = 'img/Sender.png'

    menu = UI.menu('Tools')
    menu.add_item(cmd_send)

    toolbar = UI::Toolbar.new('Speckle')
    toolbar.add_item(cmd_cube)
    toolbar.add_item(cmd_send)
    toolbar.restore

    file_loaded(__FILE__)
  end
end
