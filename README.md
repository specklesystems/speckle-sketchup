# Speckle SketchUp Connector

This is the beginning of the Speckle SketchUp Connector. It is still in very early development and is not ready for general use.

This repo is split into two parts: `speckle_connector` which is the Ruby SketchUp plugin and `ui` which is the Vue frontend. On building the `ui`, the build files will be output to `speckle_connector/html` which is where the app will be served from.

## Installation

execute:

    $ bundle install


## Usage

> NOTE: this connector is still in early development and isn't ready for general use.

The first step is to build the UI:

    cd ui
    npm install
    npm run build

This should copy the build files to `speckle_connector/html`.

You can then copy the whole `speckle_connector` folder to you SketchUp Plugins folder. You will likely find this at: 

    C:\Users\{YOU}\AppData\Roaming\SketchUp\SketchUp 2021\SketchUp\Plugins

## Development

The following instructions are for development in Windows (not WSL) using Visual Studio Code. If you would like to contribute instructions for other development environments, feel free to submit a PR.

### Environment Setup

Ruby can be installed on Windows using the installer [here](https://rubyinstaller.org/downloads/). Install it with the DevKit and complete the full installation as per instructions.

This should have also have set up the package installer `gem` and interactive ruby `irb`. Double check that everything has been installed correctly.

    ruby -v
    gem -v
    irb -v

Let's also install our first gem `bundle` which is a package manager that will help us with development.

    gem install bundle

### Editor Setup

Clone this repo and run:

    bundle install

This will install all the necessary packages for the connector.

Next, install the Sketchup Ruby Debugger. You can find installation instructions [here](https://github.com/SketchUp/sketchup-ruby-debugger/blob/main/README.md). This will involve downloading the `dll` and copying it into the SketchUp installation directory:

    C:\Program Files\SketchUp\SketchUp 2021\

You can now open up the repo in VS Code.

Make sure you've installed the Ruby extension for VS Code.

### Loading the Plugin

To tell SketchUp to load the plugin from wherever you happen to be developing, you'll need to create a ruby file with the following contents:

```ruby
$LOAD_PATH << 'C:\YOUR\PATH\TO\THE\sketchup_connector'
require 'speckle_connector.rb'
```

Drop this Ruby file into your SketchUp Plugins directory. You will likely find this at: 

    C:\Users\{YOU}\AppData\Roaming\SketchUp\SketchUp 2021\SketchUp\Plugins 

To reload the plugin while SketchUp is running, open up the Ruby console and run the following:

    SpeckleSystems::SpeckleConnector.reload

### Debugging 

To run SketchUp in debug mode, you will run the task specified in `tasks.json`. Before you do this, make sure your integrated shell for tasks is using powershell. You can specify this by adding the following option to your workspace's `settings.json`

    "terminal.integrated.automationShell.windows": "powershell.exe",

To start the task, use the keyboard shortcut `ctrl` + `shift` + `p` to open up the Command Palette. Search for `Tasks: Run Task` and select it:

![command palette](https://user-images.githubusercontent.com/7717434/135051668-35fee34e-5270-4b83-9c7b-dabb872370ee.png)

Then choose the `Debug Sketchup 2021` task to run it:

![debug sketchup task](https://user-images.githubusercontent.com/7717434/135051777-4c350a62-45fb-400e-9b24-4fbb02331b83.png)

Once Sketchup has launched, start the `Listen for rdebug-ide` debug configuration. Once the debugger has connected, you'll be able to debug the connector normally.

Make sure you've built the `ui` before starting the SketchUp Connector

    cd ui
    npm install 
    npm run build

Note that the Vue app in `ui` will need to be rebuilt every time for changes to reflected. This is because the app is being served from the `html` dir inside `speckle_connector` and being attached to the SketchUp dialog as html.