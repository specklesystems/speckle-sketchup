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

Let's also install our first gem `bundler` which is a package manager that will help us with development.

    gem install bundler

### Editor Setup

Clone this repo and run:

    bundler install

This will install all the necessary packages for the connector.

Next, install the Sketchup Ruby Debugger. You can find installation instructions 
[here](https://github.com/SketchUp/sketchup-ruby-debugger/blob/main/README.md). 
This will involve downloading the `dll` and copying it into the SketchUp installation 
directory:

    C:\Program Files\SketchUp\SketchUp 20XX\

You can now open up the repo in VS Code.

Make sure you've installed the Ruby extension for VS Code.

### Concept to load plugins into SketchUp environment

To tell SketchUp to load the plugin from wherever you happen to be developing,
you'll need to create a ruby file with the following contents:

```ruby
$LOAD_PATH << 'C:\YOUR\PATH\TO\THE\sketchup_connector'
require 'speckle_connector.rb'
```

### Loading the Speckle Connector Plugin

1. Find already prepared `speckle_connector_loader.rb` file on the `_tools`
folder.
2. Copy this Ruby file into your SketchUp Plugins directory. You will likely find this at:
    `C:\Users\{YOU}\AppData\Roaming\SketchUp\SketchUp 20XX\SketchUp\Plugins`
3. Update below line on the copied file with your local git file.
   ```ruby
    speckle_path = File.join(home_folder, 'Git', 'Speckle', 'speckle-sketchup')
   ```
   By this way SketchUp will directly read your local repository. Do not forget, 
   this file also loads additional tools on the `_tools` folder. 
   Those are will be only available on dev mode.

Due to the fact that Ruby is interpreted language, so you can reload your file(s) when
you changed them. There are different kinds of ways to reload them.

1. To reload the whole plugin files while SketchUp is running, open up the Ruby console
and run the following:
    ```ruby
    SpeckleSystems::SpeckleConnector.reload
    ```
2. To reload only specific files, use `jf ruby toolbar` plugin that already available
on SketchUp toolbar.

### User Interface

If it is your first time you cloned the project and willing to see Speckle UI, you
should make sure that you compiled the `vue.js` project in the `ui` folder.

To run the `ui`, create a `.env` based on `.env-example` and paste in your 
Speckle token. Then:

    cd ui
    npm run serve

### Debugging 

To run SketchUp in debug mode, you will run the task specified in `tasks.json`.
Before you do this, make sure your integrated shell for tasks is using powershell. 
You can specify this by adding the following option to your workspace's `settings.json`

    "terminal.integrated.automationShell.windows": "powershell.exe",

To start the task, use the keyboard shortcut `ctrl` + `shift` + `p` to open up 
the Command Palette. Search for `Tasks: Run Task` and select it:

![command palette](https://user-images.githubusercontent.com/7717434/135051668-35fee34e-5270-4b83-9c7b-dabb872370ee.png)

Then choose the `Debug Sketchup 2021` task to run it:

![debug sketchup task](https://user-images.githubusercontent.com/7717434/135051777-4c350a62-45fb-400e-9b24-4fbb02331b83.png)

Once Sketchup has launched, start the `Listen for rdebug-ide` debug configuration. 
Once the debugger has connected, you'll be able to debug the connector normally.

Make sure you run the `ui` before starting the SketchUp Connector

    cd ui
    npm run serve

### Code Quality

Tracking your code quality before merging any code to `main` branch might not seem at the
first time crucial, but when repo became huge, you might have many spaghetti code and technical
depth. It is always better to keep your work tough from the beginning. For this reason some
workflows have already setup on CI, those workflows must be passed before considering to
merge.

To track your code quality locally,

1. Make sure that you do not have any RuboCop issue, run below
   ```ruby
   bundle exec rake 
   ```
   
2. To check overall state of repository by RubyCritic, run below
   ```ruby
   rake rubycritic 
   ```