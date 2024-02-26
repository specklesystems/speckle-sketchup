# frozen_string_literal: true

require_relative 'binding'
require_relative '../../constants/path_constants'

require_relative '../../actions/base_actions/get_source_app_name'
require_relative '../../actions/base_actions/get_source_app_version'
require_relative '../../actions/get_document_info'
require_relative '../../actions/base_actions/add_model'
require_relative '../../actions/base_actions/highlight_model'
require_relative '../../actions/base_actions/remove_model'
require_relative '../../actions/base_actions/get_send_filters'
require_relative '../../actions/base_actions/update_send_filter'
require_relative '../../actions/base_actions/get_document_state'

module SpeckleConnector
  module Ui
    BASE_BINDING_NAME = 'baseBinding'

    # Binding that provided for DUI.
    class BaseBinding < Binding
      def commands
        @commands ||= {
          addModel: Commands::ActionCommand.new(@app, self, Actions::AddModel),
          highlightModel: Commands::ActionCommand.new(@app, self, Actions::HighlightModel),
          removeModel: Commands::ActionCommand.new(@app, self, Actions::RemoveModel),
          # Since we send exact model card with updateModel, I can use directly AddModel action, it will replace
          updateModel: Commands::ActionCommand.new(@app, self, Actions::AddModel),
          getSourceApplicationName: Commands::ActionCommand.new(@app, self, Actions::GetSourceAppName),
          getSourceApplicationVersion: Commands::ActionCommand.new(@app, self, Actions::GetSourceAppVersion),
          getDocumentInfo: Commands::ActionCommand.new(@app, self, Actions::GetDocumentInfo),
          updateSendFilter: Commands::ActionCommand.new(@app, self, Actions::UpdateSendFilter),
          getDocumentState: Commands::ActionCommand.new(@app, self, Actions::GetDocumentState)
        }.freeze
      end
    end
  end
end
