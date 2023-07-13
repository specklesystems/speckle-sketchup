# frozen_string_literal: true

require_relative 'view'
require_relative '../ui/dui3_dialog'
require_relative '../constants/path_constants'

require_relative '../commands/dialog_ready'
require_relative '../commands/get_commands'

require_relative '../actions/get_accounts'
require_relative '../actions/get_source_app_name'


module SpeckleConnector
  module Ui
    SPECKLE_DUI3_ID = 'speckle_dui3'

    # View that provided by vue.js
    class DUI3View < View
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

      # @return [SpeckleConnector::Ui::DUI3Dialog] wrapper for the {Sketchup::HTMLDialog}
      def dialog
        @dialog ||= SpeckleConnector::Ui::DUI3Dialog.new(commands: commands, **@dialog_specs)
      end

      def update_view(_state)
        # TODO: If you want to send data to dialog additionally, consume this method.
        #  App object triggers this method by ui_controller
      end

      def commands
        @commands ||= {
          dialog_ready: Commands::DialogReady.new(@app, self),
          getAccounts: Commands::ActionCommand.new(@app, self, Actions::GetAccounts),
          getCommands: Commands::GetCommands.new(@app, self),
          getSourceApplicationName: Commands::ActionCommand.new(@app, self, Actions::GetSourceAppName)
        }.freeze
      end
    end
  end
end
