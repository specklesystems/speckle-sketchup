# frozen_string_literal: true

require_relative '../../test_helper'
require 'io/wait'
require 'socket'
require_relative '../../../speckle_connector_3/src/auth/loopback_callback_listener'

module SpeckleConnector3
  module Auth
    # Adapter tests for the browser-login callback receiver against real local sockets.
    class LoopbackCallbackListenerTest < Minitest::Test
      POLL_BUDGET_SECONDS = 2

      def setup
        @listener = LoopbackCallbackListener.bind(port: 0)
        @clients = []
      end

      def teardown
        @clients.each { |c| c.close unless c.closed? }
        @listener.close
      end

      # The browser's request after the server redirects to http://localhost:29355?access_code=...
      def browser_request(target)
        "GET #{target} HTTP/1.1\r\n" \
          "Host: localhost:#{@listener.port}\r\n" \
          "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/141.0 Safari/537.36\r\n" \
          "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" \
          "Accept-Encoding: gzip, deflate, br\r\n" \
          "Connection: keep-alive\r\n" \
          "\r\n"
      end

      def connect
        client = TCPSocket.new('127.0.0.1', @listener.port)
        @clients << client
        client
      end

      def send_request(raw)
        client = connect
        client.write(raw)
        client
      end

      def poll_until_answered(client)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + POLL_BUDGET_SECONDS
        loop do
          result = @listener.poll
          return [result, client.read] if client.wait_readable(0)
          flunk('listener never answered the request') if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        end
      end

      def test_browser_redirect_with_access_code_completes_with_the_decoded_code
        client = send_request(browser_request('/?access_code=4f6e%2Bc0de%3D'))

        result, response = poll_until_answered(client)

        assert_predicate(result, :access_code?)
        assert_equal('4f6e+c0de=', result.access_code)
        assert_match(%r{\AHTTP/1\.1 200 OK\r\n}, response)
        assert_match(/^Connection: close\r$/, response)
        assert_match(%r{<html>.*return to SketchUp.*</html>}m, response)
      end

      def test_browser_redirect_with_denial_completes_as_denied
        client = send_request(browser_request('/?denied=true'))

        result, response = poll_until_answered(client)

        assert_predicate(result, :denied?)
        assert_nil(result.access_code)
        assert_match(%r{\AHTTP/1\.1 200 OK\r\n}, response)
        assert_match(/^Connection: close\r$/, response)
        assert_match(/Sign-in cancelled/, response)
      end

      def test_favicon_request_is_answered_and_the_code_that_follows_completes
        favicon = send_request(browser_request('/favicon.ico'))
        favicon_result, favicon_response = poll_until_answered(favicon)
        callback = send_request(browser_request('/?access_code=8c1f0a'))

        result, = poll_until_answered(callback)

        assert_predicate(favicon_result, :pending?)
        assert_match(%r{\AHTTP/1\.1 200 OK\r\n}, favicon_response)
        assert_equal('8c1f0a', result.access_code)
      end

      def test_polling_returns_immediately_without_a_thread_while_a_browser_connection_sits_idle
        threads_before = Thread.list.size
        connect
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        results = Array.new(5) { @listener.poll }

        assert(results.all?(&:pending?))
        assert_operator(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.5)
        assert_equal(threads_before, Thread.list.size)
        callback = send_request(browser_request('/?access_code=8c1f0a'))
        assert_equal('8c1f0a', poll_until_answered(callback).first.access_code)
      end

      def test_connection_closed_before_sending_a_request_is_dropped_and_waiting_continues
        connect.close
        dropped = Array.new(3) { @listener.poll }
        callback = send_request(browser_request('/?access_code=8c1f0a'))

        result, = poll_until_answered(callback)

        assert(dropped.all?(&:pending?))
        assert_equal('8c1f0a', result.access_code)
      end

      def test_client_that_resets_before_reading_the_reply_does_not_end_the_wait
        aborted = send_request(browser_request('/favicon.ico'))
        aborted.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, [1, 0].pack('ii'))
        aborted.close
        callback = send_request(browser_request('/?access_code=8c1f0a'))

        result, = poll_until_answered(callback)

        assert_equal('8c1f0a', result.access_code)
      end

      def test_close_is_idempotent_releases_the_port_and_hangs_up_waiting_connections
        idle = connect
        @listener.poll
        port = @listener.port

        2.times { @listener.close }

        assert_predicate(@listener, :closed?)
        assert(idle.wait_readable(POLL_BUDGET_SECONDS), 'idle connection was not hung up')
        assert_equal('', idle.read)
        rebound = LoopbackCallbackListener.bind(port: port)
        assert_equal(port, rebound.port)
        rebound.close
      end

      def hold_callback_port(reuse_address:)
        holder = Socket.new(:INET, :STREAM)
        holder.setsockopt(:SOCKET, :REUSEADDR, true) if reuse_address
        holder.bind(Addrinfo.tcp('127.0.0.1', LoopbackCallbackListener::DEFAULT_PORT))
        holder.listen(1)
        holder
      rescue SystemCallError => e
        holder.close
        skip("port #{LoopbackCallbackListener::DEFAULT_PORT} is held outside this test (#{e.class})")
      end

      # Windows lets a second SO_REUSEADDR bind share a port, so the holder sets it too (ENG-11163).
      def test_binding_the_callback_port_while_another_socket_holds_it_raises_busy_and_leaves_the_holder_alone
        [false, true].each do |reuse_address|
          holder = hold_callback_port(reuse_address: reuse_address)

          error = assert_raises(CallbackPortBusyError) { LoopbackCallbackListener.bind }

          assert_equal(LoopbackCallbackListener::DEFAULT_PORT, error.port)
          probe = TCPSocket.new('127.0.0.1', LoopbackCallbackListener::DEFAULT_PORT)
          refute_nil(holder.accept_nonblock(exception: false).first, "holder lost its port (reuse=#{reuse_address})")
          probe.close
          holder.close
        end
      end

      MALFORMED_REQUESTS = {
        'not an HTTP request line' => "\x16\x03\x01\x02\x00\x01\x00\x01\xfc\x03\x03\r\n\r\n".b,
        'invalid percent-encoding' => "GET /?access_code=%zz HTTP/1.1\r\nHost: localhost\r\n\r\n",
        'empty access code' => "GET /?access_code= HTTP/1.1\r\nHost: localhost\r\n\r\n",
        'oversized request head' => "GET /?access_code=#{'a' * 20_000} HTTP/1.1\r\n"
      }.freeze

      def test_malformed_requests_are_rejected_and_the_listener_keeps_waiting
        MALFORMED_REQUESTS.each do |name, raw|
          result, response = poll_until_answered(send_request(raw))

          assert_predicate(result, :pending?, name)
          assert_match(%r{\AHTTP/1\.1 400 Bad Request\r\n}, response, name)
        end
        callback = send_request(browser_request('/?access_code=8c1f0a'))

        result, = poll_until_answered(callback)

        assert_equal('8c1f0a', result.access_code)
      end
    end
  end
end
