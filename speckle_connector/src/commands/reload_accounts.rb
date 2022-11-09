# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

module SpeckleConnector
  module Commands
    # Command to receive objects from Speckle Server.
    class ReloadAccounts < Command
      def _run(data)
        puts('Reload of Speckle accounts requested by plugin')
        accounts_data = Accounts.load_accounts.to_json
        view.dialog.execute_script("loadAccounts(#{accounts_data})")
      end
    end
  end
end
