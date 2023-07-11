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
require_relative '../commands/user_preferences_updated'
require_relative '../commands/model_preferences_updated'
require_relative '../commands/activate_diffing'
require_relative '../commands/apply_mappings'
require_relative '../commands/clear_mappings'
require_relative '../commands/mapper_source_updated'

require_relative '../actions/reload_accounts'
require_relative '../actions/load_saved_streams'
require_relative '../actions/init_local_accounts'
require_relative '../actions/collect_preferences'
require_relative '../actions/deactivate_diffing'
require_relative '../actions/collect_versions'
require_relative '../actions/mapped_entities_updated'
require_relative '../actions/clear_mappings_from_table'
require_relative '../actions/isolate_mappings_from_table'
require_relative '../actions/hide_mappings_from_table'
require_relative '../actions/select_mappings_from_table'
require_relative '../actions/show_all_entities'
require_relative '../actions/clear_mapper_source'

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

      # rubocop:disable Metrics/MethodLength
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
          notify_connected: Commands::NotifyConnected.new(@app),
          collect_preferences: Commands::ActionCommand.new(@app, Actions::CollectPreferences),
          collect_versions: Commands::ActionCommand.new(@app, Actions::CollectVersions),
          user_preferences_updated: Commands::UserPreferencesUpdated.new(@app),
          model_preferences_updated: Commands::ModelPreferencesUpdated.new(@app),
          activate_diffing: Commands::ActivateDiffing.new(@app),
          deactivate_diffing: Commands::ActionCommand.new(@app, Actions::DeactivateDiffing),
          collect_mapped_entities: Commands::ActionCommand.new(@app, Actions::MappedEntitiesUpdated),
          apply_mappings: Commands::ApplyMappings.new(@app),
          clear_mappings: Commands::ClearMappings.new(@app),
          clear_mappings_from_table: Commands::ActionCommand.new(@app, Actions::ClearMappingsFromTable),
          isolate_mappings_from_table: Commands::ActionCommand.new(@app, Actions::IsolateMappingsFromTable),
          hide_mappings_from_table: Commands::ActionCommand.new(@app, Actions::HideMappingsFromTable),
          select_mappings_from_table: Commands::ActionCommand.new(@app, Actions::SelectMappingsFromTable),
          show_all_entities: Commands::ActionCommand.new(@app, Actions::ShowAllEntities),
          mapper_source_updated: Commands::MapperSourceUpdated.new(@app),
          clear_mapper_source: Commands::ActionCommand.new(@app, Actions::ClearMapperSource)
        }.freeze
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
