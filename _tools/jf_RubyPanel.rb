# frozen_string_literal: true

# #-------------------------------------------------------------------------------------------------
# *************************************************************************************************
# RubyPanel Toolbar (C) 2007 jim.foltz@gmail.com
#
# With special thanks to Chris Phillips (Sketchy Physics)
# for the Win32API code examples.
#
# 2011-01-05 <jim.foltz@gmail.com>
#   * Changed Toolbar name from "Ruby COnsole" to "Ruby Toolbar"  (TT)
#     http://forums.sketchucation.com/viewtopic.php?f=323&t=1542&p=298587#p298587
#   * Wrapped in addition module RubyToolbar
#   * Use $suString.GetSting to get proper "Ruby Console" name string.
#   * Better check if TB was previously visible
#   * Use UI.start_timer to restore Toolbar
# ICONS: located in the subfolder "rubytoolbar"
# MODIFICATION: by Fredo6 for compliance with SU 2014 (and no dependency on Win32API) - 18 Sep 2013
# *************************************************************************************************
#-------------------------------------------------------------------------------------------------

require 'sketchup'
require 'extensions'

ext = SketchupExtension.new('Ruby Toolbar', 'jf_RubyPanel/rubytoolbar.rb')
ext.creator = 'Jim Foltz <jim.foltz@gmail.com>'
ext.description = 'Toolbar for manipulating the Ruby Console. Compatible with SketchUp 2014'
ext.version = '2014'
Sketchup.register_extension(ext, true)
