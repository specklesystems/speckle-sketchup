# frozen_string_literal: true

require 'JSON'
require_relative '../constants/path_constants'

module SpeckleConnector
  # Accounts to communicate with models on user's account.
  module Accounts
    def self.load_accounts
      require_relative '../ext/sqlite3'

      db_path = SPECKLE_ACCOUNTS_DB_PATH
      unless File.exist?(db_path)
        raise(
          IOError,
          "No Accounts db found. Please read the guide for different options for adding your account:\n
             https://speckle.guide/user/manager.html#adding-accounts"
        )
      end

      db = SQLite3::Database.new(db_path)
      # FIXME: It's workaround, throws error when queried from database
      begin
        rows = db.execute('SELECT * FROM objects')
      rescue StandardError
        rows = db.execute('SELECT * FROM objects')
      end
      db.close
      rows.map { |row| JSON.parse(row[1]) }
    end

    def self.default_account
      accounts = load_accounts
      accounts.select { |acc| acc['isDefault'] }[0] || accounts[0]
    end
  end
end
