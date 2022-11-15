# frozen_string_literal: true

require 'JSON'
require_relative '../constants/path_constants'
# TODO: Below how it supposed to be
require_relative '../ext/sqlite3/sqlite3_27.so'

module SpeckleConnector
  # Accounts to communicate with models on user's account.
  module Accounts
    def self.load_accounts
      begin
        require('sqlite3')
      rescue LoadError
        # ty msp-greg! https://github.com/MSP-Greg/SUMisc/releases/tag/sqlite3-mingw-1
        # rubocop:disable SketchupRequirements/GemInstall
        # rubocop:disable Layout/LineLength
        Gem.install(File.join(File.dirname(File.expand_path(__FILE__)), '../../utils/sqlite3-1.4.2.mspgreg-x64-mingw32.gem'))
        require('sqlite3')
        # rubocop:enable SketchupRequirements/GemInstall
        # rubocop:enable Layout/LineLength
      end

      dir = SPECKLE_APPDATA_PATH
      db_path = File.join(dir, 'Accounts.db')
      unless File.exist?(db_path)
        raise(
          IOError,
          "No Accounts db found. Please read the guide for different options for adding your account:\n
             https://speckle.guide/user/manager.html#adding-accounts"
        )
      end

      db = SQLite3::Database.new(db_path)
      rows = db.execute('SELECT * FROM objects')
      db.close
      rows.map { |row| JSON.parse(row[1]) }
    end

    def self.default_account
      accounts = load_accounts
      accounts.select { |acc| acc['isDefault'] }[0] || accounts[0]
    end
  end
end
