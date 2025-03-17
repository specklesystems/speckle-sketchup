# frozen_string_literal: true

require_relative 'binding'
require_relative '../../actions/receive_bindings/receive'
require_relative '../../actions/receive_bindings/after_get_objects'

module SpeckleConnector3
  module Ui
    RECEIVE_BINDING_NAME = 'receiveBinding'

    # Receive Binding that provided for DUI.
    class ReceiveBinding < Binding
      def commands
        @commands ||= {
          receive: Commands::ActionCommand.new(@app, self, Actions::Receive),
          afterGetObjects: Commands::ActionCommand.new(@app, self, Actions::AfterGetObjects)
        }.freeze
      end
    end
  end
end
