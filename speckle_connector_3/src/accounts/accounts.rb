# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../ext/sqlite3'
require_relative '../constants/path_constants'

module SpeckleConnector3
  # Accounts to communicate with models on user's account.
  module Accounts
    # Raised when the accounts database rejects a read or write.
    class StoreError < StandardError; end

    # Load accounts from user's app data.
    def self.load_accounts(db_path: SPECKLE_ACCOUNTS_DB_PATH)
      unless File.exist?(db_path)
        create_database(db_path)
        return []
      end

      db = Sqlite3::Database.new(db_path)
      rows = db.exec('SELECT * FROM objects')
      db.close
      rows.map { |row| JSON.parse(row[1]) }
    end

    def self.add_account(account_id, account, db_path: SPECKLE_ACCOUNTS_DB_PATH)
      create_database(db_path) unless File.exist?(db_path)
      db = Sqlite3::Database.new(db_path)
      begin
        db.exec("INSERT OR REPLACE INTO objects (hash, content) VALUES (#{sql_text(account_id)}, " \
                "#{sql_text(JSON.generate(account))})")
        puts "Account with hash #{account_id} has been added/updated."
      rescue StandardError => e
        puts "An error occurred while adding the account: #{e}"
      ensure
        db.close
      end
    end

    # Saves an account under its 'id'. The first account in the store becomes the default.
    # @param account [Hash] account in the shared Accounts.db shape, including 'id'.
    # @return [Hash] the account as stored, with string keys and the resolved 'isDefault'.
    # @raise [StoreError] when the database cannot be read or written; nothing is saved then.
    def self.save_account(account, db_path: SPECKLE_ACCOUNTS_DB_PATH)
      stored = JSON.parse(JSON.generate(account))
      id = stored.fetch('id')
      create_database(db_path) unless File.exist?(db_path)
      db = Sqlite3::Database.new(db_path)
      begin
        rows = db.exec('SELECT hash, content FROM objects')
        previous = rows.find { |hash, _content| hash == id }
        # ENG-11162: re-authenticating keeps the stored default, so the user's default account does not move.
        stored['isDefault'] = previous ? JSON.parse(previous[1])['isDefault'] == true : rows.empty?
        db.exec("INSERT OR REPLACE INTO objects (hash, content) VALUES (#{sql_text(id)}, " \
                "#{sql_text(JSON.generate(stored))})")
        stored
      rescue RuntimeError, JSON::ParserError => e
        raise StoreError, "Could not save account #{id}: #{e.message}"
      ensure
        db.close
      end
    end

    def self.sql_text(value)
      "'#{value.to_s.gsub("'", "''")}'"
    end

    def self.create_database(db_path)
      FileUtils.mkdir_p(File.dirname(db_path))
      # The sqlite ext crashes the process when opening a path that does not exist yet.
      File.new(db_path, 'w').close
      db = Sqlite3::Database.new(db_path)
      create_objects_table(db)
      db.close
    end

    private_class_method :sql_text, :create_database

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

    def self.remove_account(account_id, db_path: SPECKLE_ACCOUNTS_DB_PATH)
      unless File.exist?(db_path)
        raise(
          IOError,
          "No Accounts db found. Please read the guide for different options for adding your account:\n
             https://speckle.guide/user/manager.html#adding-accounts"
        )
      end
      db = Sqlite3::Database.new(db_path)

      begin
        db.exec("DELETE FROM objects WHERE hash = #{sql_text(account_id)}")
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
