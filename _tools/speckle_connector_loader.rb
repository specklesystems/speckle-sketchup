# frozen_string_literal: true

# The purpose of this file is customizing environment of the developer on SketchUp.
# Each developer can customize it's own loader(this file), by this way developer can load their helper tools
# and helper methods ONLY in dev mode.

# Change the base folder and copy this file to Sketchup Plugins directory
# If you need to test in several versions of SketchUp, create symlinks to this file
# ( AppData\Roaming\SketchUp\SketchUp <version>\SketchUp\Plugins )
# Create a link to Plugins folder with this command
#
# New-Item -ItemType SymbolicLink -Path '~\AppData\Roaming\SketchUp\SketchUp 2022\SketchUp\Plugins\speckle_connector_loader.rb' -Target ~\Git\Speckle\speckle-sketchup\_tools\speckle_connector_loader.rb

SKETCHUP_CONSOLE.show # if you want to show Ruby console on startup
# base location of your repos - will be merged with specific repos in next step
home_folder = File.expand_path('~')
# If you use some other location for your repository, you can change it here
# but make sure it is not committed as it will change thi setting for all
# users that use the default setup. Eg:

# Add Speckle folder - uncomment the one you need
speckle_path = File.join(home_folder, 'Git', 'Speckle', 'speckle-sketchup')

$LOAD_PATH << speckle_path
$LOAD_PATH << File.join(speckle_path, '_tools')

# Defining this path will help to tool to browse related source file directly when developer attempted to reload/load file.
$JF_RUBYTOOLBAR = speckle_path

files = %w[speckle_connector jf_RubyPanel su_attributes]

files.each do |ruby_file|
  puts "Loading #{ruby_file}"
  begin
    require ruby_file
  rescue LoadError
    puts "Could not load #{ruby_file}"
  end
end
