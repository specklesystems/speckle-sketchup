# frozen_string_literal: true

require_relative 'binding'
require_relative '../actions/send_actions/add_send_card'
require_relative '../actions/send_actions/activate_send_filter'
require_relative '../actions/send_actions/activate_send_filter_tag'

module SpeckleConnector
  module Ui
    SEND_BINDING_NAME = 'sendBinding'

    # Send binding that provided for DUI.
    class SendBinding < Binding
      def commands
        @commands ||= {
          addSendCard: Commands::ActionCommand.new(@app, self, Actions::AddSendCard),
          activateSendFilter: Commands::ActionCommand.new(@app, self, Actions::ActivateSendFilter),
          activateSendFilterTag: Commands::ActionCommand.new(@app, self, Actions::ActivateSendFilterTag)
        }.freeze
      end
    end
  end
end
