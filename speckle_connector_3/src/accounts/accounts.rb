# frozen_string_literal: true

require 'JSON'
require_relative '../ext/sqlite3'
require_relative '../constants/path_constants'
require_relative '../preferences/preferences'

module SpeckleConnector3
  # Accounts to communicate with models on user's account.
  module Accounts
    # Load accounts from user's app data.
    def self.load_accounts
      db_path = SPECKLE_ACCOUNTS_DB_PATH
      unless File.exist?(db_path)
        File.new(SPECKLE_ACCOUNTS_DB_PATH, "w")
        db = Sqlite3::Database.new(SPECKLE_ACCOUNTS_DB_PATH)
        Preferences.create_objects_table(db)
        db.close
        return []
      end

      db = Sqlite3::Database.new(db_path)
      rows = db.exec('SELECT * FROM objects')
      db.close
      rows.map { |row| JSON.parse(row[1]) }
    end

    def self.add_account(account_id, account)
      unless File.exist?(SPECKLE_ACCOUNTS_DB_PATH)
        File.new(SPECKLE_ACCOUNTS_DB_PATH, "w")
        db = Sqlite3::Database.new(SPECKLE_ACCOUNTS_DB_PATH)
        create_objects_table(db)
        db.close
      end
      db = Sqlite3::Database.new(SPECKLE_ACCOUNTS_DB_PATH)
      account_json = JSON.generate(account)
      sql_query = "INSERT OR REPLACE INTO objects (hash, content) VALUES ('#{account_id}', '#{account_json}')"

      begin
        db.exec(sql_query)
        puts "Account with hash #{account_id} has been added/updated."
      rescue StandardError => e
        puts "An error occurred while adding the account: #{e}"
      ensure
        db.close
      end
    end

    # Creates the 'objects' table in the database if it doesn't already exist.
    # @param db [Sqlite3::Database] the SQLite3 database instance.
    def self.create_objects_table(db)
      db.exec <<-SQL
    CREATE TABLE IF NOT EXISTS objects (
      hash TEXT PRIMARY KEY,
      content TEXT
    );
  SQL
    end

    def self.remove_account(account_id)
      db_path = SPECKLE_ACCOUNTS_DB_PATH
      unless File.exist?(db_path)
        raise(
          IOError,
          "No Accounts db found. Please read the guide for different options for adding your account:\n
             https://speckle.guide/user/manager.html#adding-accounts"
        )
      end
      db = Sqlite3::Database.new(db_path)

      begin
        db.exec("DELETE FROM objects WHERE hash = '#{account_id}'")
        puts "Account with hash #{account_id} has been removed."
      rescue StandardError => e
        puts "An error occurred: #{e}"
      ensure
        db.close
      end
    end

    def self.get_account_by_id(id)
      accounts = load_accounts
      accounts.select { |acc| acc['id'] == id }[0]
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
