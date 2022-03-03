# frozen_string_literal: true

require "sketchup"
require "speckle_connector/dialog"
require "speckle_connector/debug"

module SpeckleSystems
  module SpeckleConnector
    unless file_loaded?(__FILE__)
      cmd_cube = UI::Command.new("Dialog") { create_dialog }
      cmd_cube.tooltip = "Launch Connector"
      cmd_cube.status_bar_text = "Opens the Speckle Connector window"
      cmd_cube.small_icon  = "icons/s2logo.png"
      cmd_cube.large_icon  = "icons/s2logo.png"

      menu = UI.menu("Tools")
      menu.add_item(cmd_cube)

      cmd_send = UI::Command.new("Send") { one_click_send }
      cmd_send.tooltip = "Send to Speckle"
      cmd_send.status_bar_text = "Send to Speckle"
      cmd_send.small_icon = "icons/Sender.png"
      cmd_send.large_icon = "icons/Sender.png"

      menu = UI.menu("Tools")
      menu.add_item(cmd_send)

      toolbar = UI::Toolbar.new("Speckle")
      toolbar.add_item(cmd_cube)
      toolbar.add_item(cmd_send)
      toolbar.restore

      file_loaded(__FILE__)

    end
  end
end
