# This is for automated pre-debugger configuration.
# We run skippy first, then activate debugger.
# The purpose of this file to wait till skp is live

# To establish a configuration
#  1. Create 'Run External Tool' before lunch step
#  2. Program -> C:\Ruby32-x64\bin\ruby.exe or whatever
#  3. Arguments -> C:\Users\KORAL\Documents\Git\Speckle\speckle-sketchup\_tools\debugger\bundle_exec_2024.rb or whatever
#  4. Working directory -> C:\Users\KORAL\Documents\Git\Speckle\speckle-sketchup or whatever

# Add a delay of 10 seconds, it is arbitrary, do not hesitate to change for what works best for you
sleep(10)

# Execute the original command
exec('bundle exec skippy sketchup:debug 2024')
