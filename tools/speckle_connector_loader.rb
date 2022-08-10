# frozen_string_literal: true

# Change the base folder and copy this file to Sketchup Plugins directory
# If you need to test in several versions of SketchUp, create symlinks to this file
# ( AppData\Roaming\SketchUp\SketchUp XXXX\SketchUp\Plugins )
# Create a link to Plugins folder with this command
#
# rubocop:disable Layout/LineLength
#
# New-Item -ItemType SymbolicLink -Path '~\AppData\Roaming\SketchUp\SketchUp 2022\SketchUp\Plugins\speckle_connector_loader.rb' -Target ~\Documents\Git\Speckle\speckle-sketchup\tools\speckle_connector_loader.rb
#
# rubocop:enable Layout/LineLength

SKETCHUP_CONSOLE.show # if you want to show Ruby console on startup
# base location of your repos - will be merged with specific repos in next step
home_folder = File.expand_path('~')
# If you use some other location for your repository, you can change it here
# but make sure it is not committed as it will change thi setting for all
# users that use the default setup. Eg:

# Add Speckle folder - uncomment the one you need
speckle_path = File.join(home_folder, 'Documents', 'Git', 'Speckle', 'speckle-sketchup')

# rubocop:disable Style/GlobalVars
$LOAD_PATH << speckle_path
# rubocop:enable Style/GlobalVars

files = %w[speckle_connector]

files.each do |ruby_file|
  puts "Loading #{ruby_file}"
  begin
    require ruby_file
  rescue LoadError
    puts "Could not load #{ruby_file}"
  end
end
