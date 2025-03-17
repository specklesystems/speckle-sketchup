# frozen_string_literal: true

require_relative 'bindings/binding'
require_relative '../actions/receive_actions/before_receive'
require_relative '../actions/receive_actions/receive_single_object'
require_relative '../actions/receive_actions/after_receive'

module SpeckleConnector
  module Ui
    RECEIVE_BINDING_NAME = 'sketchupReceiveBinding'

    # Binding that provided for DUI.
    class ReceiveBinding < Binding
      def commands
        @commands ||= {
          beforeReceive: Commands::ActionCommand.new(@app, self, Actions::BeforeReceive),
          receiveObject: Commands::ActionCommand.new(@app, self, Actions::ReceiveSingleObject),
          afterReceive: Commands::ActionCommand.new(@app, self, Actions::AfterReceive)
        }.freeze
      end
    end
  end
end
