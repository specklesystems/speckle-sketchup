# frozen_string_literal: true

require_relative 'binding'
require_relative '../../commands/deferred_action_command'
require_relative '../../actions/send_actions/send'
require_relative '../../actions/send_actions/send_artifacts'
require_relative '../../actions/send_actions/after_send_objects'
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
          # Deferred: lets the dialog repaint (card progress state) before the
          # send blocks the main thread.
          send: Commands::DeferredActionCommand.new(@app, self, Actions::Send),
          sendArtifacts: Commands::DeferredActionCommand.new(@app, self, Actions::SendArtifacts),
          getSendFilters: Commands::ActionCommand.new(@app, self, Actions::GetSendFilters),
          getSendSettings: Commands::ActionCommand.new(@app, self, Actions::GetSendSettings),
          updateSendFilter: Commands::ActionCommand.new(@app, self, Actions::UpdateSendFilter),
          afterSendObjects: Commands::ActionCommand.new(@app, self, Actions::AfterSendObjects)
        }.freeze
      end
    end
  end
end
