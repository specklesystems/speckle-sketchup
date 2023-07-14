# frozen_string_literal: true

require_relative 'view'
require_relative '../ui/dui3_dialog'
require_relative '../constants/path_constants'

require_relative '../commands/dialog_ready'

require_relative '../actions/get_accounts'
require_relative '../actions/get_source_app_name'
require_relative '../actions/get_document_info'
require_relative '../actions/say_hi_from_random'


module SpeckleConnector
  module Ui
    SKETCHUP_RANDOM_BINDING_VIEW = 'sketchupRandomBinding'

    # View that provided by vue.js
    class SketchupRandomBindingView < View
      CMD_UPDATE_VIEW = 'speckle.updateView'

      # @param app [App::SpeckleConnectorApp] the reference to the app object
      def initialize(app)
        super()
        @app = app
      end

      def update_view(_state)
        # TODO: If you want to send data to dialog additionally, consume this method.
        #  App object triggers this method by ui_controller
      end

      def commands
        @commands ||= {
          sayHiFromRandom: Commands::ActionCommand.new(@app, self, Actions::SayHiFromRandom)
        }.freeze
      end
    end
  end
end
