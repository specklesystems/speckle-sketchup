# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../support/account_builder'
require_relative '../../../speckle_connector_3/src/accounts/accounts'

module SpeckleConnector3
  # ENG-11162: the shared Accounts.db store, run against the real SQLite ext
  # outside SketchUp with an isolated database path.
  class AccountsStoreTest < Minitest::Test
    BUILD = TestSupport::AccountBuilder

    def setup
      @dir = Dir.mktmpdir('speckle-accounts')
      @db_path = File.join(@dir, 'Speckle', 'Accounts.db')
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def test_loading_without_a_database_creates_an_empty_one
      accounts = Accounts.load_accounts(db_path: @db_path)

      assert_empty accounts
      assert_path_exists @db_path
      assert_empty Accounts.load_accounts(db_path: @db_path)
    end

    def test_loading_returns_accounts_written_by_other_speckle_apps
      sdk = BUILD.sdk_account(user_name: "Seán O'Brien", company: "O'Brien & Daughters")
      dui = BUILD.dui_account
      BUILD.seed_accounts_db(@db_path, sdk, dui)

      accounts = Accounts.load_accounts(db_path: @db_path)

      assert_equal 2, accounts.size
      loaded_sdk = accounts.find { |a| a['id'] == '4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C' }
      assert_equal "Seán O'Brien", loaded_sdk['userInfo']['name']
      assert_equal "O'Brien & Daughters", loaded_sdk['userInfo']['company']
      assert_equal dui, accounts.find { |a| a['id'] == '9C8B7A6F5E4D3C2B1A0F9E8D7C6B5A49' }
    end

    def test_saving_the_first_account_makes_it_the_default
      account = BUILD.sdk_account(is_default: false)

      saved = Accounts.save_account(account, db_path: @db_path)

      assert(saved['isDefault'])
      assert_equal [saved], Accounts.load_accounts(db_path: @db_path)
      assert_equal 'sdk-token', saved['token']
    end

    def test_saving_another_account_keeps_the_existing_default_and_rows
      existing = BUILD.dui_account(is_default: true)
      BUILD.seed_accounts_db(@db_path, existing)
      added = BUILD.sdk_account(is_default: true, user_name: "Seán O'Brien")

      saved = Accounts.save_account(added, db_path: @db_path)

      refute(saved['isDefault'])
      accounts = Accounts.load_accounts(db_path: @db_path)
      assert_equal existing, accounts.find { |a| a['id'] == '9C8B7A6F5E4D3C2B1A0F9E8D7C6B5A49' }
      assert_equal "Seán O'Brien", accounts.find { |a| a['id'] == '4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C' }['userInfo']['name']
      assert_equal 2, accounts.size
    end

    def test_reauthenticating_an_account_refreshes_it_and_keeps_its_default_flag
      default = BUILD.sdk_account(is_default: true, token: 'old-token', refresh_token: 'old-refresh')
      other = BUILD.dui_account(is_default: false)
      BUILD.seed_accounts_db(@db_path, default, other)
      reauthenticated = BUILD.sdk_account(is_default: false, token: 'new-token', refresh_token: 'new-refresh',
                                          user_name: 'Ada King', company: "Lovelace's Engines")

      saved = Accounts.save_account(reauthenticated, db_path: @db_path)

      accounts = Accounts.load_accounts(db_path: @db_path)
      stored = accounts.find { |a| a['id'] == '4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C' }
      assert_equal saved, stored
      assert(stored['isDefault'])
      assert_equal 'new-token', stored['token']
      assert_equal 'new-refresh', stored['refreshToken']
      assert_equal 'Ada King', stored['userInfo']['name']
      assert_equal "Lovelace's Engines", stored['userInfo']['company']
      assert_equal other, accounts.find { |a| a['id'] == '9C8B7A6F5E4D3C2B1A0F9E8D7C6B5A49' }
      assert_equal 2, accounts.size
    end

    def test_a_rejected_save_raises_and_leaves_stored_accounts_unchanged
      existing = BUILD.sdk_account(is_default: true, token: 'old-token')
      BUILD.seed_accounts_db(@db_path, existing)
      File.chmod(0o444, @db_path)

      error = assert_raises(Accounts::StoreError) do
        Accounts.save_account(BUILD.sdk_account(token: 'new-token'), db_path: @db_path)
      end

      assert_match(/readonly/, error.message)
      assert_equal [existing], Accounts.load_accounts(db_path: @db_path)
    ensure
      File.chmod(0o644, @db_path)
    end

    def test_adding_an_account_stores_it_as_given_and_replaces_the_same_id
      existing = BUILD.dui_account(is_default: true)
      replaced = BUILD.sdk_account(is_default: true, token: 'old-token')
      BUILD.seed_accounts_db(@db_path, existing, replaced)
      added = BUILD.sdk_account(is_default: true, token: 'new-token', user_name: "Seán O'Brien")

      Accounts.add_account(added['id'], added, db_path: @db_path)

      accounts = Accounts.load_accounts(db_path: @db_path)
      stored = accounts.find { |a| a['id'] == '4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C' }
      assert_equal 'new-token', stored['token']
      assert(stored['isDefault'])
      assert_equal "Seán O'Brien", stored['userInfo']['name']
      assert_equal existing, accounts.find { |a| a['id'] == '9C8B7A6F5E4D3C2B1A0F9E8D7C6B5A49' }
      assert_equal 2, accounts.size
    end

    def test_removing_an_account_leaves_the_others
      kept = BUILD.dui_account
      removed = BUILD.sdk_account(user_name: "Seán O'Brien")
      BUILD.seed_accounts_db(@db_path, kept, removed)

      Accounts.remove_account('4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C', db_path: @db_path)

      assert_equal [kept], Accounts.load_accounts(db_path: @db_path)
    end

    def test_removing_without_a_database_raises
      assert_raises(IOError) { Accounts.remove_account('4A1B7E0C2D3F4E5A6B7C8D9E0F1A2B3C', db_path: @db_path) }
      refute_path_exists @db_path
    end
  end
end
