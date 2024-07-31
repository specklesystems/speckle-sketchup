# frozen_string_literal: true

require_relative 'bindings/binding'
require_relative '../actions/send_actions/activate_send_filter'
require_relative '../actions/send_actions/activate_send_filter_tag'

module SpeckleConnector3
  module Ui
    SEND_BINDING_NAME = 'sendBindingOld'

    # Send binding that provided for DUI.
    class SendBindingOld < Binding
      def commands
        @commands ||= {
          activateSendFilter: Commands::ActionCommand.new(@app, self, Actions::ActivateSendFilter),
          activateSendFilterTag: Commands::ActionCommand.new(@app, self, Actions::ActivateSendFilterTag)
        }.freeze
      end
    end
  end
end
