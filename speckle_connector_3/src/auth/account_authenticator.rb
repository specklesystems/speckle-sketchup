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
    # Desktop Service. One attempt runs at a time; server requests run off the host's main thread and the attempt
    # polls them and the browser callback from host timers, so the host stays responsive.
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
      # An invalid URL or a busy callback port completes the attempt before this method returns; every other
      # ending arrives on a later timer tick.
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

      # A server request on its own thread, so a slow server cannot freeze the host (ENG-11167); the attempt
      # collects the result from its timer ticks and continues with `continuation`. An attempt that ends first
      # never reads the result, and HttpClient's timeouts bound how long the thread outlives it.
      ServerCall = Struct.new(:thread, :continuation) do
        # SketchUp keeps the GVL while idle, so a thread polled only by short timer ticks never runs: measured in
        # SketchUp 2027, a threaded HTTPS request was still pending after 40 s of 0.2 s ticks, but finished in
        # 0.6 s once each tick joined it for 50 ms (ENG-11169).
        RUN_SLICE_SECONDS = 0.05

        def self.start(continuation, &request)
          thread = Thread.new do
            Thread.current.report_on_exception = false
            request.call
          end
          new(thread, continuation)
        end

        def done?
          !thread.join(RUN_SLICE_SECONDS).nil?
        end

        # @raise whatever the request raised
        def result
          thread.value
        end
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
          outcome = failure_outcome_on_error { begin_preparing(server_url) }
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
        def begin_preparing(server_url)
          @client = ServerAuthClient.new(server_url, http: @http)
          @listener = LoopbackCallbackListener.bind(host: @callback_host, port: @callback_port)
          @deadline = @clock.now + @timeout_seconds
          @server_call = ServerCall.start(method(:open_browser)) do
            @client.ensure_app_registered
            @client.new_challenge
          end
          @timer = @scheduler.start_timer(POLL_INTERVAL_SECONDS) { tick }
          nil
        end

        # A host timer can fire once more after the attempt finished; that tick must not touch a late result.
        def tick
          return if finished?

          outcome = failure_outcome_on_error { @server_call ? collect_server_call : poll_callback }
          outcome ||= AuthenticationOutcome.new(nil, AuthenticationTimeoutError.new(@timeout_seconds)) if timed_out?
          finish(outcome) if outcome
        end

        def collect_server_call
          return nil unless @server_call.done?

          call = @server_call
          @server_call = nil
          call.continuation.call(call.result)
        end

        def open_browser(challenge)
          @challenge = challenge
          @browser.open(@client.authorize_url(challenge))
          nil
        end

        def poll_callback
          callback = @listener.poll
          return redeem(callback.access_code) if callback.access_code?
          return AuthenticationOutcome.new(nil, AccessDeniedError.new) if callback.denied?

          nil
        end

        def timed_out?
          @clock.now >= @deadline
        end

        def redeem(access_code)
          @listener.close
          @server_call = ServerCall.start(method(:save)) do
            @client.account_for(@client.exchange(access_code, @challenge))
          end
          nil
        end

        # Saving stays on the host thread, behind `finished?`, so an attempt that ended meanwhile never saves.
        def save(account)
          AuthenticationOutcome.new(Accounts.save_account(account, db_path: @accounts_db_path), nil)
        end

        def failure_outcome_on_error
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
