# frozen_string_literal: true

require_relative 'bindings/binding'
require_relative '../actions/sketchup_config_actions/get_user_config'
require_relative '../actions/sketchup_config_actions/update_user_config'

module SpeckleConnector3
  module Ui
    CONNECTOR_CONFIG_BINDING_NAME = 'connectorConfigBinding'

    # Config binding that provided for DUI.
    class SketchupConfigBinding < Binding
      def commands
        @commands ||= {
          getUserConfig: Commands::ActionCommand.new(@app, self, Actions::GetUserConfig),
          updateUserConfig: Commands::ActionCommand.new(@app, self, Actions::UpdateUserConfig)
        }.freeze
      end
    end
  end
end
