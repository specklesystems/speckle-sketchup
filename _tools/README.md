# Tools

This folder stores the external tools and helper scripts to make easier life of the developer,
they are not the part of the main functionality of the Speckle.

Tools and scripts inside the folder will be loaded with `sketchup_connector_loader.rb` file.
In order to load your own `.rb` files please add this file names into list in the loader.

````ruby
...
  
files = %w[speckle_connector jf_RubyPanel su_attributes <put-your-file-here>]
# This line placed before loading started. 

files.each do |ruby_file|
  puts "Loading #{ruby_file}"
  begin
    require ruby_file
  rescue LoadError
    puts "Could not load #{ruby_file}"
  end
end
````

Track load status of your tools and scripts on the ruby console when SketchUp UI initializing. 