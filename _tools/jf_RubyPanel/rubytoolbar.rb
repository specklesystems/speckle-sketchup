# frozen_string_literal: true

#-------------------------------------------------------------------------------------------------------------------------------------------------
# RubyPanel Toolbar (C) 2007 jim.foltz@gmail.com

# Permission to use, copy, modify, and distribute this software for # any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION,
# THE IMPLIED  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# Description:   Manage the loading of Ruby files and display of the Ruby console
# CREDITS: Special thanks to Chris Phillips (Sketchy Physics) for the Win32API code examples
# Revision:  3 Aug 2009, by Fredo6
# ICONS: located in the subfolder "rubytoolbar"
# MODIFICATION: by Fredo6 for compliance with SU 2014 (and no dependency on Win32API) - 18 Sep 2013
#-------------------------------------------------------------------------------------------------------------------------------------------------

require 'English'
require 'sketchup'

module JF_RubyToolbar
  # Load the toolbar icons and commands, and do some initialization
  def self.load_toolbar
    @last_dir = "#{$LOAD_PATH[0]}/"
    @last_dir = @last_dir.gsub('/', '\\\\\\\\')
    @last_dir = File.join($JF_RUBYTOOLBAR, 'speckle_connector')
    curdir = File.dirname __FILE__

    # create toolbar
    tb = UI::Toolbar.new 'Ruby Toolbar'

    # Toggle console
    cmd = UI::Command.new('Show/Hide') { SKETCHUP_CONSOLE.visible? ? SKETCHUP_CONSOLE.hide : SKETCHUP_CONSOLE.show }
    cmd.large_icon = cmd.small_icon = File.join(curdir, 'rubypanel.png')
    cmd.status_bar_text = cmd.tooltip = 'Show/Hide Ruby Console'
    tb.add_item cmd

    # Clear Console
    cmd = UI::Command.new('Clear') { SKETCHUP_CONSOLE.clear }
    cmd.status_bar_text = cmd.tooltip = 'Clear Console'
    cmd.large_icon = cmd.small_icon = File.join(curdir, 'Delete24.png')
    tb.add_item cmd

    # Load a Ruby script
    cmd = UI::Command.new('LoadScript') { load_script }
    cmd.large_icon = cmd.small_icon = File.join(curdir, 'doc_ruby.png')
    cmd.tooltip = cmd.status_bar_text = 'Load Script'
    tb.add_item cmd

    # Reload the last Ruby Script
    @cmd_reload = UI::Command.new('Reload') { load_script @last_file }
    @cmd_reload.large_icon = @cmd_reload.small_icon = File.join(curdir, 'reload.png')
    @cmd_reload.status_bar_text = @cmd_reload.tooltip = 'Reload Script'
    tb.add_item @cmd_reload

    # Open the SU plugins directory panel
    cmd = UI::Command.new('PluginsDir') { UI.openURL @last_dir }
    cmd.tooltip = cmd.status_bar_text = 'Browse Plugins Folder'
    cmd.large_icon = cmd.small_icon = File.join(curdir, 'open_folder.png')
    tb.add_item cmd

    # showing the toolbar
    tb.get_last_state == -1 ? tb.show : tb.restore
  end

  # Load a script file - if <file> is nil, open the dialog panel to select the file
  def self.load_script(file = nil)
    file ||= UI.openpanel 'Load Script', @last_dir, '*.rb*'
    return unless file

    begin
      load file
      Sketchup.set_status_text "#{File.basename(file)} loaded (#{Time.now.strftime('%H:%M:%S')})"
      @last_file = file
      @last_dir = "#{File.dirname(file)}/"
      @last_dir = @last_dir.gsub('/', '\\\\\\\\')
      @cmd_reload.status_bar_text = @cmd_reload.tooltip = "Reload Script: #{File.basename(file)}"
    rescue StandardError
      UI.messagebox("Couldn't load #{File.basename(file)}: #{$ERROR_INFO}")
    end
  end

  # Loading the toolbar once
  unless file_loaded?('RubyToolbar.rb')
    load_toolbar
    file_loaded('RubyToolbar.rb')
  end
end
