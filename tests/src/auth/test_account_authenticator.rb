# frozen_string_literal: true

require_relative '../../test_helper'
require 'socket'
require 'tmpdir'
require_relative '../../support/account_builder'
require_relative '../../support/fake_speckle_server'
require_relative '../../support/sign_in_host'
require_relative '../../../speckle_connector_3/src/accounts/accounts'
require_relative '../../../speckle_connector_3/src/auth/account_authenticator'

module SpeckleConnector3
  module Auth
    # ENG-11167: browser sign-in from SketchUp, driven through the native authentication entry point that the
    # accountsBinding's authenticateAccount calls (the bridge itself needs a running SketchUp), against a real
    # temporary Accounts.db, a real loopback callback port and an in-process Speckle server.
    class AccountAuthenticatorTest < Minitest::Test
      BUILD = TestSupport::AccountBuilder
      TOKENS = TestSupport::FakeSpeckleServer::DEFAULT_TOKENS
      SECOND_TOKENS = {
        'token' => '0d2e4f6a8c1b3d5f7e9a0c2e4b6d8f1a3c5e7b9d2f',
        'refreshToken' => '6b4d2f0e8c6a4b2d0f9e7c5a3b1d9f7e5c3a1b0d8e'
      }.freeze
      SEAN = 'sean.obrien@example.com'

      def setup
        @dir = Dir.mktmpdir('speckle-native-auth')
        @db_path = File.join(@dir, 'Speckle', 'Accounts.db')
        @callback_port = TestSupport.free_local_port
        @scheduler = TestSupport::ManualScheduler.new
        @clock = TestSupport::FakeClock.new
        @servers = []
        @browsers = []
        @holders = []
      end

      def teardown
        @authenticator&.cancel
        @browsers.each(&:close)
        @servers.each(&:stop)
        @holders.each { |holder| holder.close unless holder.closed? }
        FileUtils.remove_entry(@dir)
      end

      def start_server(**options)
        server = TestSupport::FakeSpeckleServer.new(callback_url: "http://localhost:#{@callback_port}", **options)
        @servers << server
        server
      end

      def browser_for(server, user_action: :approve)
        browser = TestSupport::FakeBrowser.new(server, user_action: user_action)
        @browsers << browser
        browser
      end

      def authenticator_with(browser)
        @authenticator = AccountAuthenticator.new(
          browser: browser, scheduler: @scheduler, clock: @clock,
          http: HttpClient.new(open_timeout: 2, read_timeout: 2),
          accounts_db_path: @db_path, callback_port: @callback_port
        )
      end

      # @return [Array<AuthenticationOutcome>] filled when the attempt completes
      def sign_in(server_url, authenticator)
        outcomes = []
        authenticator.authenticate(server_url) { |outcome| outcomes << outcome }
        outcomes
      end

      def complete(outcomes)
        @scheduler.tick_until { !outcomes.empty? }
        outcomes.first
      end

      def saved_accounts
        Accounts.load_accounts(db_path: @db_path)
      end

      def existing_accounts(server)
        [
          BUILD.sdk_account(is_default: true, email: 'ada@example.com', server_url: 'https://app.speckle.systems'),
          BUILD.dui_account(id: BUILD.sdk_id('grace@example.com', server.url), is_default: false,
                            email: 'grace@example.com', server_url: server.url)
        ]
      end

      def callback_port_free?
        TCPServer.new('127.0.0.1', @callback_port).close
        true
      rescue SystemCallError
        false
      end

      def expected_account(server, tokens: TOKENS, is_default: true)
        {
          'id' => BUILD.sdk_id(SEAN, server.url),
          'token' => tokens['token'],
          'refreshToken' => tokens['refreshToken'],
          'isDefault' => is_default,
          'isOnline' => true,
          'serverInfo' => {
            'name' => 'Speckle', 'company' => 'Speckle Systems', 'version' => server.version,
            'description' => 'The Speckle server', 'frontend2' => true, 'url' => server.url,
            'migration' => { 'movedFrom' => nil, 'movedTo' => nil }
          },
          'userInfo' => {
            'id' => '7c1e5a9b3d', 'name' => "Seán O'Brien", 'email' => SEAN,
            'company' => "O'Brien & Partners", 'avatar' => nil
          }
        }
      end

      def test_first_sign_in_on_a_current_server_saves_the_account_as_the_default
        server = start_server(version: :current)

        outcome = complete(sign_in(server.url, authenticator_with(browser_for(server))))

        assert_predicate outcome, :success?
        assert_equal expected_account(server), outcome.account
        assert_equal [expected_account(server)], saved_accounts
        assert_equal [:oauth_token], server.exchanges.map(&:endpoint)
      end

      def test_sign_in_opens_the_browser_and_waits_on_host_timers_without_blocking
        server = start_server(version: :current)
        browser = browser_for(server, user_action: :none)

        outcomes = sign_in(server.url, authenticator_with(browser))

        assert_empty outcomes
        assert_equal 1, @scheduler.running_timers
        assert_match(%r{\A#{server.url}/authn/verify/connectrV3/[A-Za-z0-9_-]{43}\?code_challenge_method=S256\z},
                     browser.opened_urls.first)
        browser.approve(browser.opened_urls.first)
        assert_equal expected_account(server), complete(outcomes).account
        assert_equal 0, @scheduler.running_timers
        assert_match(/Authentication complete/, browser.callback_page)
      end

      def test_adding_an_account_on_a_2_31_server_uses_the_legacy_exchange_and_keeps_the_other_accounts
        server = start_server(version: :minimum)
        existing = existing_accounts(server)
        BUILD.seed_accounts_db(@db_path, *existing)
        browser = browser_for(server)

        outcome = complete(sign_in("#{server.url}/", authenticator_with(browser)))

        added = expected_account(server, is_default: false)
        assert_equal added, outcome.account
        assert_equal (existing + [added]).sort_by { |a| a['id'] }, saved_accounts.sort_by { |a| a['id'] }
        assert_equal [:auth_token], server.exchanges.map(&:endpoint)
        assert_match(%r{/authn/verify/connectrV3/[A-Za-z0-9_-]{43}\z}, browser.opened_urls.first)
      end

      def test_signing_in_again_refreshes_the_saved_account_and_keeps_its_identity_and_default
        server = start_server(version: :current, tokens: [SECOND_TOKENS])
        previous = BUILD.dui_account(id: BUILD.sdk_id(SEAN, server.url), token: 'expired-token',
                                     refresh_token: 'expired-refresh', is_default: true, email: SEAN,
                                     server_url: server.url)
        other = BUILD.sdk_account(is_default: false)
        BUILD.seed_accounts_db(@db_path, previous, other)

        outcome = complete(sign_in("#{server.url}/", authenticator_with(browser_for(server))))

        refreshed = expected_account(server, tokens: SECOND_TOKENS, is_default: true)
        assert_equal refreshed, outcome.account
        assert_equal [other, refreshed].sort_by { |a| a['id'] }, saved_accounts.sort_by { |a| a['id'] }
      end

      def test_a_server_older_than_2_31_fails_with_upgrade_guidance_before_the_browser_opens
        server = start_server(version: :before_minimum)
        existing = existing_accounts(server)
        BUILD.seed_accounts_db(@db_path, *existing)
        browser = browser_for(server)

        outcome = complete(sign_in(server.url, authenticator_with(browser)))

        assert_kind_of AuthAppUnavailableError, outcome.error
        assert_match(/2\.31\.0 or later/, outcome.error.message)
        assert_empty browser.opened_urls
        assert_equal existing, saved_accounts
        assert_predicate self, :callback_port_free?
      end

      def test_a_busy_callback_port_fails_without_touching_its_holder_and_a_retry_works_once_it_is_free
        server = start_server(version: :current)
        holder = TCPServer.new('127.0.0.1', @callback_port)
        @holders << holder
        browser = browser_for(server)
        authenticator = authenticator_with(browser)

        busy = complete(sign_in(server.url, authenticator))

        assert_kind_of CallbackPortBusyError, busy.error
        assert_empty browser.opened_urls
        assert_empty saved_accounts
        TCPSocket.new('127.0.0.1', @callback_port).close
        assert IO.select([holder], nil, nil, 2), 'the holder no longer accepts connections'
        holder.close
        assert_equal expected_account(server), complete(sign_in(server.url, authenticator)).account
      end

      def test_declining_in_the_browser_ends_the_attempt_and_saves_nothing
        server = start_server(version: :current)
        existing = existing_accounts(server)
        BUILD.seed_accounts_db(@db_path, *existing)
        browser = browser_for(server, user_action: :deny)

        outcome = complete(sign_in(server.url, authenticator_with(browser)))

        assert_kind_of AccessDeniedError, outcome.error
        assert_equal existing, saved_accounts
        assert_empty server.exchanges
        assert_predicate self, :callback_port_free?
      end

      def test_cancelling_a_waiting_attempt_saves_nothing_and_a_retry_signs_in
        server = start_server(version: :current)
        browser = browser_for(server, user_action: :none)
        authenticator = authenticator_with(browser)
        cancelled = sign_in(server.url, authenticator)

        authenticator.cancel

        assert_equal 1, cancelled.size
        assert_kind_of AuthenticationCancelledError, cancelled.first.error
        assert_equal 0, @scheduler.running_timers
        assert_predicate self, :callback_port_free?
        assert_empty saved_accounts
        retry_outcomes = sign_in(server.url, authenticator)
        browser.approve(browser.opened_urls.last)
        assert_equal expected_account(server), complete(retry_outcomes).account
        assert_equal 1, cancelled.size
      end

      def test_an_attempt_times_out_after_five_minutes_and_a_retry_signs_in
        server = start_server(version: :current)
        browser = browser_for(server, user_action: :none)
        authenticator = authenticator_with(browser)
        timed_out = sign_in(server.url, authenticator)

        @clock.advance(299)
        @scheduler.tick
        still_waiting = timed_out.empty?
        @clock.advance(1)
        @scheduler.tick

        assert still_waiting
        assert_kind_of AuthenticationTimeoutError, timed_out.first.error
        assert_match(/after 5 minutes/, timed_out.first.error.message)
        assert_predicate self, :callback_port_free?
        assert_empty saved_accounts
        retry_outcomes = sign_in(server.url, authenticator)
        browser.approve(browser.opened_urls.last)
        assert_equal expected_account(server), complete(retry_outcomes).account
      end

      def test_a_newer_attempt_replaces_a_waiting_one_whose_late_timer_cannot_take_its_callback
        server = start_server(version: :current)
        browser = browser_for(server, user_action: :none)
        authenticator = authenticator_with(browser)
        replaced = sign_in(server.url, authenticator)
        current = sign_in(server.url, authenticator)

        browser.approve(browser.opened_urls.last)
        @scheduler.fire_stopped_timers

        assert_equal expected_account(server), complete(current).account
        assert_equal 1, replaced.size
        assert_kind_of AuthenticationCancelledError, replaced.first.error
        assert_equal [expected_account(server)], saved_accounts
      end

      def test_a_code_approved_in_a_replaced_attempts_tab_is_rejected_and_saves_nothing
        server = start_server(version: :current)
        existing = existing_accounts(server)
        BUILD.seed_accounts_db(@db_path, *existing)
        browser = browser_for(server, user_action: :none)
        authenticator = authenticator_with(browser)
        sign_in(server.url, authenticator)
        current = sign_in(server.url, authenticator)

        browser.approve(browser.opened_urls.first)
        outcome = complete(current)

        assert_kind_of TokenExchangeRejectedError, outcome.error
        assert_match(/Code challenge mismatch/, outcome.error.message)
        assert_equal existing, saved_accounts
        assert_predicate self, :callback_port_free?
      end

      def test_a_network_failure_during_the_exchange_saves_nothing_and_a_retry_signs_in
        server = start_server(version: :current)
        existing = existing_accounts(server)
        BUILD.seed_accounts_db(@db_path, *existing)
        server.fail_request('POST', '/oauth/token', :drop)
        authenticator = authenticator_with(browser_for(server))

        failed = complete(sign_in(server.url, authenticator))

        assert_kind_of ServerRequestError, failed.error
        assert_equal existing, saved_accounts
        assert_predicate self, :callback_port_free?
        retried = complete(sign_in(server.url, authenticator))
        assert_equal expected_account(server, is_default: false), retried.account
      end

      def test_a_server_error_while_reading_the_signed_in_user_saves_nothing
        server = start_server(version: :current)
        existing = existing_accounts(server)
        BUILD.seed_accounts_db(@db_path, *existing)
        server.fail_request('POST', '/graphql', 500, skip: 1)

        outcome = complete(sign_in(server.url, authenticator_with(browser_for(server))))

        assert_kind_of ServerRequestError, outcome.error
        assert_equal existing, saved_accounts
      end

      def test_an_invalid_server_address_fails_before_the_browser_opens
        server = start_server(version: :current)
        browser = browser_for(server)

        outcome = complete(sign_in('speckle.example.com', authenticator_with(browser)))

        assert_kind_of InvalidServerUrlError, outcome.error
        assert_empty browser.opened_urls
        assert_predicate self, :callback_port_free?
      end

      def test_an_unreachable_server_fails_before_the_browser_opens
        server = start_server(version: :current)
        server.stop
        browser = browser_for(server)

        outcome = complete(sign_in(server.url, authenticator_with(browser)))

        assert_kind_of ServerRequestError, outcome.error
        assert_empty browser.opened_urls
        assert_predicate self, :callback_port_free?
        assert_empty saved_accounts
      end
    end
  end
end
