# frozen_string_literal: true

require_relative 'binding'
require_relative '../actions/config_actions/get_config'
require_relative '../actions/config_actions/update_config'

module SpeckleConnector
  module Ui
    CONFIG_BINDING_NAME = 'configBinding'

    # Config binding that provided for DUI.
    class ConfigBinding < Binding
      def commands
        @commands ||= {
          getConfig: Commands::ActionCommand.new(@app, self, Actions::GetConfig),
          updateConfig: Commands::ActionCommand.new(@app, self, Actions::UpdateConfig)
        }.freeze
      end
    end
  end
end
