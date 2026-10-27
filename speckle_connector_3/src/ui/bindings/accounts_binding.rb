# frozen_string_literal: true

require_relative 'binding'
require_relative '../../commands/action_command'
require_relative '../../commands/authenticate_account_command'
require_relative '../../actions/account_actions/get_accounts'
require_relative '../../actions/account_actions/add_account'
require_relative '../../actions/account_actions/remove_account'

module SpeckleConnector3
  module Ui
    ACCOUNTS_BINDING_NAME = 'accountsBinding'

    # Binding that provided for DUI.
    class AccountsBinding < Binding
      # @param authenticator [Auth::AccountAuthenticator, nil] browser sign-in behind authenticateAccount; nil uses
      #   SketchUp's browser and timers
      def initialize(app, name, authenticator: nil)
        super(app, name)
        @authenticator = authenticator
      end

      # authenticateAccount is what the DUI checks to offer native sign-in and hide Log in (Legacy); addAccount
      # stays because the DUI's Log in button requires it (spec 2026-10-sketchup-native-authentication, ADR-0001).
      def commands
        @commands ||= {
          getAccounts: Commands::ActionCommand.new(@app, self, Actions::GetAccounts),
          addAccount: Commands::ActionCommand.new(@app, self, Actions::AddAccount),
          removeAccount: Commands::ActionCommand.new(@app, self, Actions::RemoveAccount),
          authenticateAccount: Commands::AuthenticateAccountCommand.new(@app, self, authenticator: @authenticator)
        }.freeze
      end
    end
  end
end
