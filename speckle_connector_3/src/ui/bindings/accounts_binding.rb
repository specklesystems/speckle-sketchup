# frozen_string_literal: true

require_relative 'binding'
require_relative '../../actions/get_accounts'

module SpeckleConnector3
  module Ui
    ACCOUNTS_BINDING_NAME = 'accountsBinding'

    # Binding that provided for DUI.
    class AccountsBinding < Binding
      def commands
        @commands ||= {
          getAccounts: Commands::ActionCommand.new(@app, self, Actions::GetAccounts)
        }.freeze
      end
    end
  end
end
