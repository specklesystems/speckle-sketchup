# frozen_string_literal: true

require_relative 'binding'
require_relative '../../actions/base_actions/get_send_filters'
require_relative '../../actions/base_actions/update_send_filter'

module SpeckleConnector
  module Ui
    SEND_BINDING_NAME = 'sendBinding'

    # Send Binding that provided for DUI.
    class SendBinding < Binding
      def commands
        @commands ||= {
          getSendFilters: Commands::ActionCommand.new(@app, self, Actions::GetSendFilters),
          updateSendFilter: Commands::ActionCommand.new(@app, self, Actions::UpdateSendFilter)
        }.freeze
      end
    end
  end
end
