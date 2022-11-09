# frozen_string_literal: true

require_relative 'view'
require_relative '../ui/dialog'
require_relative '../constants/path_constants'
require_relative '../commands/dialog_ready'
require_relative '../commands/send_selection'

module SpeckleConnector
  module Ui
    SPECKLE_UI_ID = 'speckle_ui'
    VUE_UI_HTML = Pathname.new(File.join(SPECKLE_SRC_PATH, '..', 'vue_ui', 'index.html')).cleanpath.to_s

    # View that provided by vue.js
    class VueView < View
      CMD_UPDATE_VIEW = 'speckle.updateView'

      # @param dialog_specs [Hash] the specifications for the {SpeckleConnector::Ui::Dialog}.
      # @param app [App::SpeckleConnectorApp] the reference to the app object
      def initialize(dialog_specs, app)
        super()
        @dialog_specs = dialog_specs
        @app = app
      end

      # Show the HTML dialog
      def show
        dialog.show
      end

      # @return [SpeckleConnector::Ui::Dialog] wrapper for the {Sketchup::HTMLDialog}
      def dialog
        @dialog ||= SpeckleConnector::Ui::Dialog.new(commands: commands, **@dialog_specs)
      end

      private

      def commands
        @commands ||= {
          dialog_ready: Commands::DialogReady.new(@app, 'dialog_ready'),
          send_selection: Commands::SendSelection.new(@app, 'convertedFromSketchup'),
          receive_objects: Commands::ReceiveObjects.new(@app, 'finishedReceiveInSketchup'),
        }.freeze
      end
    end
  end
end
