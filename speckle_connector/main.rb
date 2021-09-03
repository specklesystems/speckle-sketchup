# frozen_string_literal: true

require "sketchup"
require "speckle_connector/dialog.rb"

module SpeckleSystems
  module SpeckleConnector
    def self.create_cube
      model = Sketchup.active_model

      model.start_operation("Create Cube", true)

      group = model.active_entities.add_group
      entities = group.entities
      points = [
        Geom::Point3d.new(0,   0,   0),
        Geom::Point3d.new(1.m, 0,   0),
        Geom::Point3d.new(1.m, 1.m, 0),
        Geom::Point3d.new(0,   1.m, 0)
      ]
      face = entities.add_face(points)
      face.pushpull(-1.m)

      model.commit_operation
    end

    def self.send
      puts("Sending")
      model = Sketchup.active_model
      instances = model.selection.each { |entity| puts(entity) }
    end

    def self.receive
      puts("Receiving")
    end

    unless file_loaded?(__FILE__)

      menu = UI.menu("Plugins")
      menu.add_item("01 Create Cube Example") do
        create_cube
      end

      cmd_cube = UI::Command.new("Dialog") { show_dialog }
      cmd_cube.tooltip = "Launch Connector"
      cmd_cube.status_bar_text = "Opens the Speckle Connector window"
      cmd_cube.small_icon  = "icons/s2logo.png"
      cmd_cube.large_icon  = "icons/s2logo.png"

      menu = UI.menu("Tools")
      menu.add_item(cmd_cube)

      cmd_send = UI::Command.new("Send") { send }
      cmd_send.tooltip = "Send to Speckle"
      cmd_send.status_bar_text = "Send to Speckle"
      cmd_send.small_icon = "icons/Sender.png"
      cmd_send.large_icon = "icons/Sender.png"

      menu = UI.menu("Tools")
      menu.add_item(cmd_send)

      cmd_receive = UI::Command.new("Receive") { receive }
      cmd_receive.tooltip = "Receive from Speckle"
      cmd_receive.status_bar_text = "Receive from Speckle"
      cmd_receive.small_icon = "icons/Receiver.png"
      cmd_receive.large_icon = "icons/Receiver.png"

      menu = UI.menu("Tools")
      menu.add_item(cmd_receive)

      toolbar = UI::Toolbar.new("Speckle")
      toolbar.add_item(cmd_cube)
      toolbar.add_item(cmd_send)
      toolbar.add_item(cmd_receive)
      toolbar.restore

      file_loaded(__FILE__)

    end
  end
end
