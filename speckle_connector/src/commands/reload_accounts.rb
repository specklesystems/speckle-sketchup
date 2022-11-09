# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative 'load_saved_streams'

module SpeckleConnector
  module Commands
    # Command to reload accounts from database.
    class ReloadAccounts < Command
      def _run(data)
        puts 'Reload of Speckle accounts requested by plugin'
        accounts_data = Accounts.load_accounts.to_json
        view.dialog.execute_script("loadAccounts(#{accounts_data})")
        Commands::LoadSavedStreams.new(app, 'reloadAccounts')._run(data)
      end
    end
  end
end
