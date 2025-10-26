# frozen_string_literal: true

require_relative 'binding'
require_relative '../../actions/account_actions/get_accounts'
require_relative '../../actions/account_actions/add_account'
require_relative '../../actions/account_actions/remove_account'

module SpeckleConnector3
  module Ui
    ACCOUNTS_BINDING_NAME = 'accountsBinding'

    # Binding that provided for DUI.
    class AccountsBinding < Binding
      def commands
        @commands ||= {
          getAccounts: Commands::ActionCommand.new(@app, self, Actions::GetAccounts),
          addAccount: Commands::ActionCommand.new(@app, self, Actions::AddAccount),
          removeAccount: Commands::ActionCommand.new(@app, self, Actions::RemoveAccount)
        }.freeze
      end
    end
  end
end
