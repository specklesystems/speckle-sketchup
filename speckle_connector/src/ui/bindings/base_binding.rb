# frozen_string_literal: true

require_relative 'binding'
require_relative '../../constants/path_constants'

require_relative '../../actions/get_source_app_name'
require_relative '../../actions/get_document_info'
require_relative '../../actions/base_actions/get_send_filters'
require_relative '../../actions/base_actions/update_send_filter'
require_relative '../../actions/base_actions/get_model_state'
require_relative '../../actions/base_actions/get_document_state'
require_relative '../../actions/base_actions/add_model_to_document_state'

module SpeckleConnector
  module Ui
    BASE_BINDING_NAME = 'baseBinding'

    # Binding that provided for DUI.
    class BaseBinding < Binding
      def commands
        @commands ||= {
          getSourceApplicationName: Commands::ActionCommand.new(@app, self, Actions::GetSourceAppName),
          getDocumentInfo: Commands::ActionCommand.new(@app, self, Actions::GetDocumentInfo),
          getSendFilters: Commands::ActionCommand.new(@app, self, Actions::GetSendFilters),
          updateSendFilter: Commands::ActionCommand.new(@app, self, Actions::UpdateSendFilter),
          getModelState: Commands::ActionCommand.new(@app, self, Actions::GetModelState),
          getDocumentState: Commands::ActionCommand.new(@app, self, Actions::GetDocumentState),
          addModelToDocumentState: Commands::ActionCommand.new(@app, self, Actions::AddModelToDocumentState)
        }.freeze
      end
    end
  end
end
