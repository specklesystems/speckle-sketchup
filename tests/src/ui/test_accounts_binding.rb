# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/account_builder'
require_relative '../../support/bridge_host'
require_relative '../../support/sign_in_host'
require_relative '../../../speckle_connector_3/src/ui/bindings/accounts_binding'

module SpeckleConnector3
  module Ui
    # ENG-11168: the accountsBinding as the DUI drives it (`getBindingsMethodNames` reads `commands.keys`, a call
    # runs `commands[name].run(request_id, *args)`), observed at the dialog through the scripts the app executes.
    # The HtmlDialog and SketchUp's timers/browser are the only stand-ins; sign-in runs the real authenticator
    # against an in-process Speckle server, a real loopback port and a temporary Accounts.db.
    class AccountsBindingTest < Minitest::Test
      include TestSupport::SignInFixtures

      def setup
        super
        @dialog = TestSupport::FakeDialog.new
      end

      def binding_with(browser, unflushed: [])
        app = TestSupport::BridgeHost.app(@dialog, unflushed: unflushed)
        AccountsBinding.new(app, ACCOUNTS_BINDING_NAME, authenticator: authenticator_with(browser))
      end

      def authenticate_account(binding, request_id, server_url)
        binding.commands[:authenticateAccount].run(request_id, server_url)
      end

      def tick_until_answered(request_id)
        @scheduler.tick_until { @dialog.responses_to(request_id).any? }
      end

      def test_the_dui_finds_authenticate_account_beside_the_existing_account_methods
        binding = AccountsBinding.new(TestSupport::BridgeHost.app(@dialog), ACCOUNTS_BINDING_NAME)

        assert_equal %i[getAccounts addAccount removeAccount authenticateAccount].sort, binding.commands.keys.sort
      end

      def test_a_sign_in_answers_its_request_with_the_saved_account_once_the_browser_returns
        server = start_server(version: :current)
        binding = binding_with(browser_for(server, user_action: :none))

        authenticate_account(binding, 'accountsBinding_1', server.url)
        page = opened_page(@browsers.last)
        assert_empty @dialog.responses, 'answered before the user signed in'
        @browsers.last.approve(page)
        tick_until_answered('accountsBinding_1')
        @scheduler.tick

        saved = saved_accounts
        assert_equal 1, saved.size
        assert_equal TestSupport::FakeSpeckleServer::DEFAULT_TOKENS['token'], saved.first['token']
        assert_equal [TestSupport::FakeDialog::Response.new('accountsBinding', 'accountsBinding_1', saved.first)],
                     @dialog.responses
      end

      def test_an_invalid_server_address_answers_the_request_during_the_call
        server = start_server(version: :current)
        binding = binding_with(browser_for(server))

        authenticate_account(binding, 'accountsBinding_1', 'speckle.example.com')
        answered_during_call = @dialog.responses_to('accountsBinding_1').size
        @scheduler.tick

        assert_equal 1, answered_during_call
        response = @dialog.responses_to('accountsBinding_1').first
        assert_match(/not a valid server address/, response.data['message'])
        assert_equal [response], @dialog.responses
        assert_empty @browsers.last.opened_urls
        assert_empty saved_accounts
      end

      def test_a_server_without_the_sign_in_app_answers_the_request_with_an_error_on_a_later_tick
        server = start_server(version: :before_minimum)
        binding = binding_with(browser_for(server))

        authenticate_account(binding, 'accountsBinding_1', server.url)
        assert_empty @dialog.responses
        tick_until_answered('accountsBinding_1')
        @scheduler.tick

        response = @dialog.responses_to('accountsBinding_1').first
        assert_match(/2\.31\.0/, response.data['message'])
        assert_equal [response], @dialog.responses
        assert_empty @browsers.last.opened_urls
        assert_empty saved_accounts
      end

      def test_a_sign_in_declined_in_the_browser_answers_its_request_with_an_error_on_a_later_tick
        server = start_server(version: :current)
        binding = binding_with(browser_for(server, user_action: :deny))

        authenticate_account(binding, 'accountsBinding_1', server.url)
        assert_empty @dialog.responses
        tick_until_answered('accountsBinding_1')
        @scheduler.tick

        response = @dialog.responses_to('accountsBinding_1').first
        assert_kind_of String, response.data['message']
        assert response.data.key?('error'), 'the DUI only rejects responses carrying an error'
        assert_equal [response], @dialog.responses
        assert_empty saved_accounts
      end

      def test_a_new_sign_in_replaces_a_pending_one_and_each_request_is_answered_once
        server = start_server(version: :current)
        binding = binding_with(browser_for(server, user_action: :none))

        authenticate_account(binding, 'accountsBinding_1', server.url)
        opened_page(@browsers.last)
        authenticate_account(binding, 'accountsBinding_2', server.url)
        replaced = @dialog.responses_to('accountsBinding_1')
        @browsers.last.approve(opened_page(@browsers.last, 2))
        tick_until_answered('accountsBinding_2')
        @scheduler.tick

        assert_equal 1, replaced.size
        assert replaced.first.data.key?('error')
        assert_equal [replaced.first, TestSupport::FakeDialog::Response.new('accountsBinding', 'accountsBinding_2',
                                                                            saved_accounts.first)],
                     @dialog.responses
      end

      def test_a_sign_in_answer_does_not_replace_another_requests_answer_still_in_the_queue
        server = start_server(version: :current)
        earlier = TestSupport::AccountBuilder.sdk_account
        binding = binding_with(browser_for(server),
                               unflushed: [[Actions::CompleteAuthenticateAccount, 'accountsBinding_1', earlier]])

        authenticate_account(binding, 'accountsBinding_2', server.url)
        tick_until_answered('accountsBinding_2')

        assert_equal [earlier], @dialog.responses_to('accountsBinding_1').map(&:data)
        assert_equal [saved_accounts.first], @dialog.responses_to('accountsBinding_2').map(&:data)
      end

      def test_a_failure_while_answering_a_sign_in_answers_the_request_with_that_error
        server = start_server(version: :current)
        binding = binding_with(browser_for(server))
        @dialog.fail_next_script(RuntimeError.new('The Speckle window was closed.'))

        authenticate_account(binding, 'accountsBinding_1', server.url)
        @scheduler.tick_until { @dialog.responses_to('accountsBinding_1').any? { |r| r.data.key?('error') } }

        errors = @dialog.responses_to('accountsBinding_1').select { |r| r.data.key?('error') }
        assert_equal(['The Speckle window was closed.'], errors.map { |r| r.data['message'] })
      end

      def test_a_sign_in_error_does_not_replace_another_requests_error_still_in_the_queue
        server = start_server(version: :before_minimum)
        earlier = Actions::HandleError.new(RuntimeError.new('earlier failure'), ACCOUNTS_BINDING_NAME,
                                           Actions::CompleteAuthenticateAccount, ['accountsBinding_1'])
        binding = binding_with(browser_for(server), unflushed: [earlier])

        authenticate_account(binding, 'accountsBinding_2', server.url)
        tick_until_answered('accountsBinding_2')

        assert_equal(['earlier failure'], @dialog.responses_to('accountsBinding_1').map { |r| r.data['message'] })
        assert_match(/2\.31\.0/, @dialog.responses_to('accountsBinding_2').first.data['message'])
      end
    end
  end
end
