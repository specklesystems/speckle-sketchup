# frozen_string_literal: true

require "sketchup"
require "speckle_connector/dialog.rb"
require "speckle_connector/debug.rb"

module SpeckleSystems
  module SpeckleConnector
    unless file_loaded?(__FILE__)
      cmd_cube = UI::Command.new("Dialog") { show_dialog }
      cmd_cube.tooltip = "Launch Connector"
      cmd_cube.status_bar_text = "Opens the Speckle Connector window"
      cmd_cube.small_icon  = "icons/s2logo.png"
      cmd_cube.large_icon  = "icons/s2logo.png"

      menu = UI.menu("Tools")
      menu.add_item(cmd_cube)

      toolbar = UI::Toolbar.new("Speckle")
      toolbar.add_item(cmd_cube)
      toolbar.restore

      file_loaded(__FILE__)

    end
  end
end
