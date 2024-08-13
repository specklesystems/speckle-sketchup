# frozen_string_literal: true

require_relative 'binding'
require_relative '../../actions/send_actions/send'
require_relative '../../actions/base_actions/get_send_filters'
require_relative '../../actions/base_actions/get_send_settings'
require_relative '../../actions/base_actions/update_send_filter'

module SpeckleConnector3
  module Ui
    SEND_BINDING_NAME = 'sendBinding'

    # Send Binding that provided for DUI.
    class SendBinding < Binding
      def commands
        @commands ||= {
          send: Commands::ActionCommand.new(@app, self, Actions::Send),
          getSendFilters: Commands::ActionCommand.new(@app, self, Actions::GetSendFilters),
          getSendSettings: Commands::ActionCommand.new(@app, self, Actions::GetSendSettings),
          updateSendFilter: Commands::ActionCommand.new(@app, self, Actions::UpdateSendFilter)
        }.freeze
      end
    end
  end
end
