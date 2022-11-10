# frozen_string_literal: true

require_relative 'view'
require_relative '../ui/dialog'
require_relative '../constants/path_constants'

require_relative '../commands/send_selection'
require_relative '../commands/receive_objects'
require_relative '../commands/action_command'
require_relative '../commands/dialog_ready'
require_relative '../commands/save_stream'
require_relative '../commands/remove_stream'
require_relative '../commands/notify_connected'

require_relative '../actions/reload_accounts'
require_relative '../actions/load_saved_streams'
require_relative '../actions/init_local_accounts'

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

      def update_view(_state)
        # TODO: If you want to send data to dialog additionally, consume this method.
        #  App object triggers this method by ui_controller
      end

      private

      def commands
        @commands ||= {
          dialog_ready: Commands::DialogReady.new(@app),
          send_selection: Commands::SendSelection.new(@app),
          receive_objects: Commands::ReceiveObjects.new(@app),
          reload_accounts: Commands::ActionCommand.new(@app, Actions::ReloadAccounts),
          init_local_accounts: Commands::ActionCommand.new(@app, Actions::InitLocalAccounts),
          load_saved_streams: Commands::ActionCommand.new(@app, Actions::LoadSavedStreams),
          save_stream: Commands::SaveStream.new(@app),
          remove_stream: Commands::RemoveStream.new(@app),
          notify_connected: Commands::NotifyConnected.new(@app)
        }.freeze
      end
    end
  end
end
