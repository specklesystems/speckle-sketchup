# frozen_string_literal: true

require_relative 'errors'
require_relative 'http_client'
require_relative 'loopback_callback_listener'
require_relative 'server_auth_client'
require_relative '../accounts/accounts'

module SpeckleConnector3
  module Auth
    # How a sign-in attempt ended: the saved account, or the error that stopped it before anything was saved.
    AuthenticationOutcome = Struct.new(:account, :error) do
      def success?
        error.nil?
      end
    end

    # Signs a user in through the system browser and saves the account into the shared Accounts.db, without
    # Desktop Service. One attempt runs at a time; the wait for the browser is polled from host timers, so the
    # host stays responsive.
    class AccountAuthenticator
      DEFAULT_TIMEOUT_SECONDS = 300
      POLL_INTERVAL_SECONDS = 0.2

      # Seconds from a monotonic source, unaffected by wall-clock changes.
      module MonotonicClock
        def self.now
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end

      # @param browser [#open] opens a URL in the system browser
      # @param scheduler [#start_timer, #stop_timer] `start_timer(interval_seconds) { }` starts a repeating timer and
      #   returns its id; `stop_timer(id)` stops it (UI.start_timer / UI.stop_timer in SketchUp)
      # @param clock [#now] monotonic seconds
      # @param http [#get, #post_json] see HttpClient
      # rubocop:disable Metrics/ParameterLists
      def initialize(browser:, scheduler:, clock: MonotonicClock, http: HttpClient.new,
                     accounts_db_path: SPECKLE_ACCOUNTS_DB_PATH,
                     callback_host: LoopbackCallbackListener::DEFAULT_HOST,
                     callback_port: LoopbackCallbackListener::DEFAULT_PORT,
                     timeout_seconds: DEFAULT_TIMEOUT_SECONDS)
        @options = {
          browser: browser, scheduler: scheduler, clock: clock, http: http, accounts_db_path: accounts_db_path,
          callback_host: callback_host, callback_port: callback_port, timeout_seconds: timeout_seconds
        }
        @current = nil
      end
      # rubocop:enable Metrics/ParameterLists

      # Starts a sign-in against `server_url`, cancelling an attempt that is still waiting.
      # Failures found before the browser opens (invalid URL, busy callback port, server without the sign-in
      # app, unreachable server) complete the attempt before this method returns.
      # @yieldparam outcome [AuthenticationOutcome] exactly once per attempt
      # @return [Attempt]
      def authenticate(server_url, &on_complete)
        @current&.cancel(AuthenticationCancelledError.new('Sign-in was replaced by a newer sign-in attempt.'))
        @current = Attempt.new(on_complete: on_complete, **@options)
        @current.start(server_url)
        @current
      end

      def cancel
        @current&.cancel
      end

      # One browser sign-in, from binding the callback port to a saved account or an error.
      class Attempt
        # rubocop:disable Metrics/ParameterLists
        def initialize(browser:, scheduler:, clock:, http:, accounts_db_path:, callback_host:, callback_port:,
                       timeout_seconds:, on_complete:)
          @browser = browser
          @scheduler = scheduler
          @clock = clock
          @http = http
          @accounts_db_path = accounts_db_path
          @callback_host = callback_host
          @callback_port = callback_port
          @timeout_seconds = timeout_seconds
          @on_complete = on_complete
          @finished = false
        end
        # rubocop:enable Metrics/ParameterLists

        def start(server_url)
          outcome = protect { begin_waiting(server_url) }
          finish(outcome) if outcome
        end

        def cancel(error = AuthenticationCancelledError.new)
          finish(AuthenticationOutcome.new(nil, error))
        end

        def finished?
          @finished
        end

        private

        # The listener binds before the browser opens so the callback cannot arrive before anyone listens.
        def begin_waiting(server_url)
          @client = ServerAuthClient.new(server_url, http: @http)
          @listener = LoopbackCallbackListener.bind(host: @callback_host, port: @callback_port)
          @client.ensure_app_registered
          @challenge = @client.new_challenge
          @deadline = @clock.now + @timeout_seconds
          @timer = @scheduler.start_timer(POLL_INTERVAL_SECONDS) { tick }
          @browser.open(@client.authorize_url(@challenge))
          nil
        end

        def tick
          outcome = protect { poll_callback }
          finish(outcome) if outcome
        end

        def poll_callback
          callback = @listener.poll
          return redeem(callback.access_code) if callback.access_code?
          return AuthenticationOutcome.new(nil, AccessDeniedError.new) if callback.denied?
          return AuthenticationOutcome.new(nil, AuthenticationTimeoutError.new(@timeout_seconds)) if timed_out?

          nil
        end

        def timed_out?
          @clock.now >= @deadline
        end

        # The timer stops before the blocking exchange so a host timer re-firing meanwhile cannot redeem twice.
        def redeem(access_code)
          release
          tokens = @client.exchange(access_code, @challenge)
          account = @client.account_for(tokens)
          AuthenticationOutcome.new(Accounts.save_account(account, db_path: @accounts_db_path), nil)
        end

        def protect
          yield
        rescue StandardError => e
          AuthenticationOutcome.new(nil, e)
        end

        def finish(outcome)
          return if finished?

          @finished = true
          release
          @on_complete&.call(outcome)
        end

        def release
          @scheduler.stop_timer(@timer) if @timer
          @timer = nil
          @listener&.close
        end
      end
    end
  end
end
