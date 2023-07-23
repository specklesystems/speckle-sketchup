# frozen_string_literal: true

require 'JSON'
require_relative '../ext/sqlite3'
require_relative '../constants/path_constants'

module SpeckleConnector
  # Accounts to communicate with models on user's account.
  module Accounts
    # Load accounts from user's app data.
    def self.load_accounts
      db_path = SPECKLE_ACCOUNTS_DB_PATH
      unless File.exist?(db_path)
        raise(
          IOError,
          "No Accounts db found. Please read the guide for different options for adding your account:\n
             https://speckle.guide/user/manager.html#adding-accounts"
        )
      end

      db = Sqlite3::Database.new(db_path)
      rows = db.exec('SELECT * FROM objects')
      db.close
      rows.map { |row| JSON.parse(row[1]) }
    end

    # Default account on the user computer.
    def self.default_account
      accounts = load_accounts
      accounts.select { |acc| acc['isDefault'] }[0] || accounts[0]
    end

    # Try to get local server account for debug/test purposes.
    def self.try_get_local_server_account
      accounts = load_accounts
      accounts.select { |acc| acc['serverInfo']['url'].include?('localhost') }[0] || nil
    end
  end
end
