<h1 align="center">
  <img src="https://user-images.githubusercontent.com/2679513/131189167-18ea5fe1-c578-47f6-9785-3748178e4312.png" width="150px"/><br/>
  Speckle | SketchUp
</h1>
<h3 align="center">
    Connector for SketchUp
</h3>
<p align="center"><b>Speckle</b> is the data infrastructure for the AEC industry.</p><br/>

<p align="center"><a href="https://twitter.com/SpeckleSystems"><img src="https://img.shields.io/twitter/follow/SpeckleSystems?style=social" alt="Twitter Follow"></a> <a href="https://speckle.community"><img src="https://img.shields.io/discourse/users?server=https%3A%2F%2Fspeckle.community&amp;style=flat-square&amp;logo=discourse&amp;logoColor=white" alt="Community forum users"></a> <a href="https://speckle.systems"><img src="https://img.shields.io/badge/https://-speckle.systems-royalblue?style=flat-square" alt="website"></a> <a href="https://speckle.guide/dev/"><img src="https://img.shields.io/badge/docs-speckle.guide-orange?style=flat-square&amp;logo=read-the-docs&amp;logoColor=white" alt="docs"></a></p>
<p align="center"><a href="https://github.com/specklesystems/speckle-blender/"><img src="https://circleci.com/gh/specklesystems/speckle-blender.svg?style=svg&amp;circle-token=76eabd350ea243575cbb258b746ed3f471f7ac29" alt="Speckle-Next"></a> </p>

# About Speckle

What is Speckle? Check our ![YouTube Video Views](https://img.shields.io/youtube/views/B9humiSpHzM?label=Speckle%20in%201%20minute%20video&style=social)

### Features

- **Object-based:** say goodbye to files! Speckle is the first object based platform for the AEC industry
- **Version control:** Speckle is the Git & Hub for geometry and BIM data
- **Collaboration:** share your designs collaborate with others
- **3D Viewer:** see your CAD and BIM models online, share and embed them anywhere
- **Interoperability:** get your CAD and BIM models into other software without exporting or importing
- **Real time:** get real time updates and notifications and changes
- **GraphQL API:** get what you need anywhere you want it
- **Webhooks:** the base for a automation and next-gen pipelines
- **Built for developers:** we are building Speckle with developers in mind and got tools for every stack
- **Built for the AEC industry:** Speckle connectors are plugins for the most common software used in the industry such as Revit, Rhino, Grasshopper, AutoCAD, Civil 3D, Excel, Unreal Engine, Unity, QGIS, Blender and more!

### Try Speckle now!

Give Speckle a try in no time by:

- [![speckle XYZ](https://img.shields.io/badge/https://-speckle.xyz-0069ff?style=flat-square&logo=hackthebox&logoColor=white)](https://speckle.xyz) ⇒ creating an account at our public server
- [![create a droplet](https://img.shields.io/badge/Create%20a%20Droplet-0069ff?style=flat-square&logo=digitalocean&logoColor=white)](https://marketplace.digitalocean.com/apps/speckle-server?refcode=947a2b5d7dc1) ⇒ deploying an instance in 1 click 

### Resources

- [![Community forum users](https://img.shields.io/badge/community-forum-green?style=for-the-badge&logo=discourse&logoColor=white)](https://speckle.community) for help, feature requests or just to hang with other speckle enthusiasts, check out our community forum!
- [![website](https://img.shields.io/badge/tutorials-speckle.systems-royalblue?style=for-the-badge&logo=youtube)](https://speckle.systems) our tutorials portal is full of resources to get you started using Speckle
- [![docs](https://img.shields.io/badge/docs-speckle.guide-orange?style=for-the-badge&logo=read-the-docs&logoColor=white)](https://speckle.guide/user/blender.html) reference on almost any end-user and developer functionality


# Repo structure

This is the beginning of the Speckle SketchUp Connector. It is still in very early development and is not ready for general use.

This repo is split into two parts: `speckle_connector` which is the Ruby SketchUp plugin and `ui` which is the Vue frontend.

## Usage

> NOTE: this connector is still in early development and isn't ready for general use.

Copy the whole `speckle_connector` folder to you SketchUp Plugins folder. You will likely find this at: 

    C:\Users\{YOU}\AppData\Roaming\SketchUp\SketchUp 2021\SketchUp\Plugins


You'll need to serve the ui before launching the connector:

    cd ui
    npm install
    npm run serve


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

To run the `ui`, create a `.env` based on `.env-example` and paste in your Speckle token. Then:

    cd ui
    npm run serve

### Debugging 

To run SketchUp in debug mode, you will run the task specified in `tasks.json`. Before you do this, make sure your integrated shell for tasks is using powershell. You can specify this by adding the following option to your workspace's `settings.json`

    "terminal.integrated.automationShell.windows": "powershell.exe",

To start the task, use the keyboard shortcut `ctrl` + `shift` + `p` to open up the Command Palette. Search for `Tasks: Run Task` and select it:

![command palette](https://user-images.githubusercontent.com/7717434/135051668-35fee34e-5270-4b83-9c7b-dabb872370ee.png)

Then choose the `Debug Sketchup 2021` task to run it:

![debug sketchup task](https://user-images.githubusercontent.com/7717434/135051777-4c350a62-45fb-400e-9b24-4fbb02331b83.png)

Once Sketchup has launched, start the `Listen for rdebug-ide` debug configuration. Once the debugger has connected, you'll be able to debug the connector normally.

Make sure you run the `ui` before starting the SketchUp Connector

    cd ui
    npm run serve