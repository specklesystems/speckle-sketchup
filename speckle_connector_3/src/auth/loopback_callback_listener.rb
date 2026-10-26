# frozen_string_literal: true

require 'socket'
require 'uri'

module SpeckleConnector3
  module Auth
    # Outcome of one poll of the loopback listener.
    CallbackResult = Struct.new(:status, :access_code) do
      def pending?
        status == :pending
      end

      def access_code?
        status == :access_code
      end

      def denied?
        status == :denied
      end
    end

    # The browser-login callback port is held by another socket (another connector's login, or any other app).
    class CallbackPortBusyError < StandardError
      attr_reader :host, :port

      def initialize(host, port, cause_error)
        @host = host
        @port = port
        super("Cannot listen for the sign-in callback on #{host}:#{port}: the port is in use " \
              "by another application (#{cause_error.class.name.split('::').last}).")
      end
    end

    # Receives the server's browser-login redirect on a loopback port without blocking the host:
    # every call to #poll accepts and reads only what is already waiting on the socket.
    class LoopbackCallbackListener
      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 29355

      PENDING = CallbackResult.new(:pending).freeze
      DENIED = CallbackResult.new(:denied).freeze
      MALFORMED = CallbackResult.new(:malformed).freeze
      private_constant :MALFORMED

      READ_CHUNK_BYTES = 4096
      MAX_HEAD_BYTES = 8192
      MAX_DISCARD_READS = 16
      HEAD_TERMINATOR = "\r\n\r\n"
      REQUEST_LINE = %r{\A(?<method>[A-Z]+) (?<target>\S+) HTTP/\d\.\d\z}.freeze

      PAGE_TEMPLATE = '<!doctype html><html><head><meta charset="utf-8"><title>Speckle</title></head>' \
                      '<body style="font-family:sans-serif;text-align:center;padding-top:80px">%s</body></html>'
      SUCCESS_PAGE = '<h2>Authentication complete</h2><p>You can close this window and return to SketchUp.</p>'
      DENIED_PAGE = '<h2>Sign-in cancelled</h2><p>You can close this window and return to SketchUp.</p>'

      attr_reader :host, :port

      # TCPServer sets SO_REUSEADDR only off Windows: POSIX needs it to rebind past TIME_WAIT, while on Windows
      # it would let us share a port another process holds. A .NET HttpListener (http.sys) holder surfaces as
      # EACCES rather than EADDRINUSE (ENG-11163).
      # @raise [CallbackPortBusyError] when another socket holds the port; that socket is left untouched
      def self.bind(host: DEFAULT_HOST, port: DEFAULT_PORT)
        new(TCPServer.new(host, port), host)
      rescue Errno::EADDRINUSE, Errno::EACCES => e
        raise CallbackPortBusyError.new(host, port, e)
      end

      private_class_method :new

      def initialize(server, host)
        @server = server
        @host = host
        @port = server.addr[1]
        @connections = []
      end

      # @return [CallbackResult] pending until a callback carrying an access code or a denial arrives
      def poll
        accept_waiting_connections
        @connections.dup.each do |connection|
          head = read_head(connection)
          next if head == :wait_readable

          @connections.delete(connection)
          next drop(connection[:socket]) if head.nil?

          result = answer(connection[:socket], head)
          return result if result.access_code? || result.denied?
        end
        PENDING
      end

      def close
        @connections.each { |connection| drop(connection[:socket]) }
        @connections.clear
        @server.close unless @server.closed?
      end

      def closed?
        @server.closed?
      end

      private

      def accept_waiting_connections
        loop do
          socket = @server.accept_nonblock(exception: false)
          break if socket == :wait_readable

          @connections << { socket: socket, buffer: String.new(encoding: Encoding::BINARY) }
        rescue Errno::ECONNABORTED, Errno::ECONNRESET
          next
        end
      end

      # @return [String, :wait_readable, nil] the request head once it has fully arrived, nil if the peer went away
      def read_head(connection)
        loop do
          chunk = connection[:socket].read_nonblock(READ_CHUNK_BYTES, exception: false)
          return chunk unless chunk.is_a?(String)

          connection[:buffer] << chunk
          head_end = connection[:buffer].index(HEAD_TERMINATOR)
          return connection[:buffer][0, head_end] if head_end
          return '' if connection[:buffer].bytesize > MAX_HEAD_BYTES
        end
      rescue SystemCallError, IOError
        nil
      end

      def drop(socket)
        socket.close
      rescue SystemCallError, IOError
        nil
      end

      def answer(socket, head)
        result = classify(head)
        case result.status
        when :malformed then respond(socket, '400 Bad Request', '')
        when :denied then respond(socket, '200 OK', DENIED_PAGE)
        when :access_code then respond(socket, '200 OK', SUCCESS_PAGE)
        else respond(socket, '200 OK', '')
        end
        result
      end

      def classify(head)
        match = REQUEST_LINE.match(head.lines.first.to_s.chomp)
        return MALFORMED unless match

        path, query = match[:target].split('?', 2)
        return PENDING unless match[:method] == 'GET' && path == '/' && query

        classify_callback_query(query)
      end

      def classify_callback_query(query)
        return MALFORMED if query.match?(/%(?![0-9A-Fa-f]{2})/)

        params = URI.decode_www_form(query).to_h
        return DENIED if params['denied'] == 'true'
        return PENDING unless params.key?('access_code')
        return MALFORMED if params['access_code'].empty?

        CallbackResult.new(:access_code, params['access_code']).freeze
      rescue ArgumentError
        MALFORMED
      end

      def respond(socket, status, page)
        body = page.empty? ? '' : format(PAGE_TEMPLATE, page)
        socket.write("HTTP/1.1 #{status}\r\nContent-Type: text/html; charset=utf-8\r\n" \
                     "Content-Length: #{body.bytesize}\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n#{body}")
        discard_unread_input(socket)
      rescue SystemCallError, IOError
        nil
      ensure
        drop(socket)
      end

      # Closing a socket with unread input sends a reset, which can destroy the reply before the browser reads it.
      def discard_unread_input(socket)
        MAX_DISCARD_READS.times do
          chunk = socket.read_nonblock(READ_CHUNK_BYTES, exception: false)
          break unless chunk.is_a?(String)
        end
      end
    end
  end
end
