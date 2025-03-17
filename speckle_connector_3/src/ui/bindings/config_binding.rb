# frozen_string_literal: true

require_relative 'binding'
require_relative '../../actions/config_actions/get_is_dev_mode'
require_relative '../../actions/config_actions/get_config'
require_relative '../../actions/config_actions/update_config'
require_relative '../../actions/config_actions/get_user_selected_account_id'
require_relative '../../actions/config_actions/set_user_selected_account_id'

module SpeckleConnector3
  module Ui
    CONFIG_BINDING_NAME = 'configBinding'

    # Config binding that provided for DUI.
    class ConfigBinding < Binding
      def commands
        @commands ||= {
          getIsDevMode: Commands::ActionCommand.new(@app, self, Actions::GetIsDevMode),
          getConfig: Commands::ActionCommand.new(@app, self, Actions::GetConfig),
          updateConfig: Commands::ActionCommand.new(@app, self, Actions::UpdateConfig),
          getUserSelectedAccountId: Commands::ActionCommand.new(@app, self, Actions::GetUserSelectedAccountId),
          setUserSelectedAccountId: Commands::ActionCommand.new(@app, self, Actions::SetUserSelectedAccountId)
        }.freeze
      end
    end
  end
end
