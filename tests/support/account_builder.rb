# frozen_string_literal: true

require 'digest'
require 'json'
require 'fileutils'
require_relative '../../speckle_connector_3/src/ext/sqlite3'

module SpeckleConnector3
  module TestSupport
    # Accounts as other Speckle apps write them into the shared Accounts.db.
    module AccountBuilder
      # Shape written by the .NET SDK (Manager, Revit, Rhino, ...).
      def self.sdk_account(id: '4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C', token: 'sdk-token', refresh_token: 'sdk-refresh',
                           is_default: false, user_name: 'Ada Lovelace', email: 'ada@example.com',
                           company: 'Analytical Engines', server_url: 'https://app.speckle.systems')
        {
          'id' => id,
          'token' => token,
          'refreshToken' => refresh_token,
          'isDefault' => is_default,
          'isOnline' => true,
          'serverInfo' => {
            'name' => 'Speckle',
            'company' => 'Speckle Systems',
            'version' => '2.25.4',
            'description' => 'The Speckle server',
            'frontend2' => true,
            'url' => server_url,
            'migration' => { 'movedFrom' => nil, 'movedTo' => nil }
          },
          'userInfo' => {
            'id' => 'f00dfeed01',
            'name' => user_name,
            'email' => email,
            'company' => company,
            'avatar' => nil
          }
        }
      end

      # Shape written by the hosted DUI token exchange through `addAccount`.
      def self.dui_account(id: '9C8B7A6F5E4D3C2B1A0F9E8D7C6B5A49', token: 'dui-token', refresh_token: 'dui-refresh',
                           is_default: true, user_name: 'Grace Hopper', email: 'grace@example.com',
                           company: 'Compilers Inc', server_url: 'https://speckle.example.com')
        {
          'id' => id,
          'token' => token,
          'refreshToken' => refresh_token,
          'isDefault' => is_default,
          'serverInfo' => {
            'name' => 'Example Speckle',
            'company' => 'Example Ltd',
            'adminContact' => 'admin@example.com',
            'description' => 'Self-hosted',
            'url' => server_url
          },
          'userInfo' => {
            'id' => 'c0ffee0002',
            'name' => user_name,
            'email' => email,
            'company' => company,
            'avatar' => 'https://speckle.example.com/avatar.png'
          }
        }
      end

      # Account id as the .NET SDK and the hosted DUI derive it: MD5 of email + server URL, upper-case hex.
      def self.sdk_id(email, server_url)
        Digest::MD5.hexdigest(email + server_url).upcase
      end

      # Writes rows the way the SDK does, independently of the code under test.
      def self.seed_accounts_db(db_path, *accounts)
        FileUtils.mkdir_p(File.dirname(db_path))
        File.new(db_path, 'w').close unless File.exist?(db_path)
        db = Sqlite3::Database.new(db_path)
        db.exec('CREATE TABLE IF NOT EXISTS objects (hash TEXT PRIMARY KEY, content TEXT)')
        accounts.each do |account|
          content = JSON.generate(account).gsub("'", "''")
          db.exec("INSERT INTO objects (hash, content) VALUES ('#{account['id']}', '#{content}')")
        end
        db.close
      end
    end
  end
end
