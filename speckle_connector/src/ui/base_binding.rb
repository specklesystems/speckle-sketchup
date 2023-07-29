# frozen_string_literal: true

require_relative 'binding'
require_relative '../ui/dui3_dialog'
require_relative '../constants/path_constants'

require_relative '../actions/get_accounts'
require_relative '../actions/get_source_app_name'
require_relative '../actions/get_document_info'
require_relative '../actions/base_actions/get_send_filter'
require_relative '../actions/base_actions/update_send_filter'
require_relative '../actions/base_actions/get_model_state'

module SpeckleConnector
  module Ui
    BASE_BINDING_NAME = 'baseBinding'

    # Binding that provided for DUI.
    class BaseBinding < Binding
      def commands
        @commands ||= {
          getAccounts: Commands::ActionCommand.new(@app, self, Actions::GetAccounts),
          getSourceApplicationName: Commands::ActionCommand.new(@app, self, Actions::GetSourceAppName),
          getDocumentInfo: Commands::ActionCommand.new(@app, self, Actions::GetDocumentInfo),
          getSendFilter: Commands::ActionCommand.new(@app, self, Actions::GetSendFilter),
          updateSendFilter: Commands::ActionCommand.new(@app, self, Actions::UpdateSendFilter),
          getModelState: Commands::ActionCommand.new(@app, self, Actions::GetModelState)
        }.freeze
      end
    end
  end
end
