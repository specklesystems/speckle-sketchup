# frozen_string_literal: true

require 'io/wait'
require 'socket'
require 'uri'

module SpeckleConnector3
  module TestSupport
    # Stands in for the system browser: records what SketchUp opens and, acting as the user, approves or denies
    # on the server's authorization page, then follows the server's redirect to the loopback callback.
    class FakeBrowser
      attr_reader :opened_urls

      # @param user_action [Symbol] :approve or :deny right after the page opens, :none to leave the tab alone
      def initialize(server, user_action: :approve)
        @server = server
        @user_action = user_action
        @opened_urls = []
        @connections = []
      end

      def open(url)
        @opened_urls << url
        case @user_action
        when :approve then approve(url)
        when :deny then follow(@server.deny(url))
        end
      end

      def approve(authorize_url)
        follow(@server.approve(authorize_url))
      end

      # @return [String, nil] the page the callback answered with, once it has answered
      def callback_page(index = -1)
        socket = @connections[index]
        socket.wait_readable(0) ? socket.read : nil
      end

      def close
        @connections.each { |socket| socket.close unless socket.closed? }
      end

      private

      def follow(redirect_url)
        uri = URI(redirect_url)
        socket = TCPSocket.new('127.0.0.1', uri.port)
        socket.write("GET /?#{uri.query} HTTP/1.1\r\nHost: #{uri.host}:#{uri.port}\r\n" \
                     "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/141.0 Safari/537.36\r\n" \
                     "Accept: text/html\r\nConnection: keep-alive\r\n\r\n")
        @connections << socket
      end
    end

    # Repeating timers driven by the test, in place of SketchUp's UI.start_timer / UI.stop_timer.
    class ManualScheduler
      def initialize
        @timers = {}
        @stopped = []
        @next_id = 0
      end

      def start_timer(_interval_seconds, &tick)
        @next_id += 1
        @timers[@next_id] = tick
        @next_id
      end

      def stop_timer(timer_id)
        stopped = @timers.delete(timer_id)
        @stopped << stopped if stopped
      end

      # A host timer can still fire once after it was stopped (a tick already queued by the host).
      def fire_stopped_timers
        @stopped.each(&:call)
      end

      def running_timers
        @timers.size
      end

      def tick
        @timers.values.each(&:call)
      end

      # Ticks like SketchUp's idle loop until the block holds; real sockets need a moment to deliver.
      def tick_until(budget_seconds: 3)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + budget_seconds
        until yield
          raise 'condition not reached while ticking' if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

          tick
          sleep(0.005)
        end
      end
    end

    # Monotonic clock the test moves forward.
    class FakeClock
      attr_reader :now

      def initialize
        @now = 1000.0
      end

      def advance(seconds)
        @now += seconds
      end
    end

    def self.free_local_port
      server = TCPServer.new('127.0.0.1', 0)
      port = server.addr[1]
      server.close
      port
    end
  end
end
