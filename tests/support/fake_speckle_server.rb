# frozen_string_literal: true

require 'digest'
require 'json'
require 'securerandom'
require 'socket'
require 'uri'

module SpeckleConnector3
  module TestSupport
    # An in-process Speckle server speaking the connector sign-in protocol over real HTTP: the connectrV3 app
    # lookup, the token-endpoint probe, access codes bound to a challenge (what the server's authorization page
    # issues once the user approves), the legacy and OAuth token exchanges with the server's challenge checks,
    # and the GraphQL user/server details behind an issued token.
    class FakeSpeckleServer
      APP_ID = 'connectrV3'

      VERSIONS = {
        current: { version: '2026.9.7', oauth_token_endpoint: true, connector_app: true },
        minimum: { version: '2.31.0', oauth_token_endpoint: false, connector_app: true },
        before_minimum: { version: '2.30.2', oauth_token_endpoint: false, connector_app: false }
      }.freeze

      DEFAULT_USER = {
        'id' => '7c1e5a9b3d',
        'name' => "Seán O'Brien",
        'email' => 'sean.obrien@example.com',
        'company' => "O'Brien & Partners",
        'avatar' => nil
      }.freeze

      DEFAULT_TOKENS = {
        'token' => '3f1c9a7e5b2d4c6e8a0b1d3f5e7a9c1b2d4f6a8c0e',
        'refreshToken' => '9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c'
      }.freeze

      INTERNAL_ERROR = { 'errors' => [{ 'message' => 'Internal server error' }] }.freeze

      Exchange = Struct.new(:endpoint, :status)

      attr_reader :url, :exchanges, :version

      def initialize(version: :current, callback_url: 'http://localhost:29355', user: DEFAULT_USER,
                     tokens: [DEFAULT_TOKENS])
        config = VERSIONS.fetch(version)
        @version = config[:version]
        @oauth_token_endpoint = config[:oauth_token_endpoint]
        @connector_app = config[:connector_app]
        @callback_url = callback_url
        @user = user
        @tokens_to_issue = tokens.dup
        @issued_tokens = []
        @codes = {}
        @exchanges = []
        @served = []
        @failures = {}
        @held = Queue.new
        @lock = Mutex.new
        @server = TCPServer.new('127.0.0.1', 0)
        @url = "http://127.0.0.1:#{@server.addr[1]}"
        @thread = Thread.new { serve }
      end

      def stop
        @server.close unless @server.closed?
        @thread.join(2)
      end

      def server_info
        {
          'name' => 'Speckle', 'company' => 'Speckle Systems', 'description' => 'The Speckle server',
          'version' => @version, 'migration' => { 'movedFrom' => nil, 'movedTo' => nil }
        }
      end

      # What the server's authorization page does when the signed-in user approves the app.
      # @return [String] the URL the server redirects the browser to
      def approve(authorize_url)
        uri = URI(authorize_url)
        match = %r{\A/authn/verify/(?<app>[^/]+)/(?<challenge>[^/]+)\z}.match(uri.path)
        raise "not an authorization page: #{authorize_url}" unless match && uri.to_s.start_with?(@url)
        raise "app #{match[:app]} does not exist on this server" unless match[:app] == APP_ID && @connector_app

        method = URI.decode_www_form(uri.query.to_s).to_h['code_challenge_method']
        code = SecureRandom.hex(5)
        @lock.synchronize { @codes[code] = { challenge: match[:challenge], hash_algorithm: method } }
        "#{@callback_url}?access_code=#{code}"
      end

      def deny(_authorize_url)
        "#{@callback_url}?denied=true"
      end

      # After `skip` matching requests, the next `method path` request gets `status` instead of its normal answer;
      # status :drop closes the connection without answering, like a network failure mid-request, and :hold answers
      # normally once the test calls `release_held_request`, like a slow server.
      def fail_request(method, path, status, skip: 0)
        @lock.synchronize { @failures[[method, path]] = { status: status, skip: skip } }
      end

      # @return [Array<Array(String, String)>] `[method, path]` of every request answered so far
      def served_requests
        @lock.synchronize { @served.dup }
      end

      def holding_request?
        !@held.empty?
      end

      def release_held_request
        @held.pop << true
      end

      private

      def serve
        loop do
          client = @server.accept
          Thread.new(client) { |socket| handle(socket) }
        end
      rescue IOError, SystemCallError
        nil
      end

      def handle(socket)
        method, path, headers, body = read_request(socket)
        failure = take_failure(method, path)
        return if failure == :drop

        failure = wait_for_release if failure == :hold
        status, content = failure ? [failure, INTERNAL_ERROR] : route(method, path, headers, body)
        write_response(socket, status, content)
        @lock.synchronize { @served << [method, path] }
      rescue IOError, SystemCallError
        nil
      ensure
        socket.close unless socket.closed?
      end

      def wait_for_release
        Queue.new.tap { |release| @held << release }.pop
        nil
      end

      def take_failure(method, path)
        @lock.synchronize do
          failure = @failures[[method, path]]
          next nil unless failure

          if failure[:skip] > 0
            failure[:skip] -= 1
            next nil
          end

          @failures.delete([method, path])[:status]
        end
      end

      def read_request(socket)
        request_line = socket.gets("\r\n").to_s.chomp
        method, target = request_line.split
        headers = {}
        while (line = socket.gets("\r\n")) && line != "\r\n"
          name, value = line.chomp.split(':', 2)
          headers[name.downcase] = value.to_s.strip
        end
        body = socket.read(headers['content-length'].to_i)
        [method, URI(target.to_s).path, headers, body.to_s]
      end

      def write_response(socket, status, content)
        body = content.is_a?(String) ? content : JSON.generate(content)
        type = content.is_a?(String) ? 'text/html; charset=utf-8' : 'application/json; charset=utf-8'
        socket.write("HTTP/1.1 #{status} X\r\nContent-Type: #{type}\r\nContent-Length: #{body.bytesize}\r\n" \
                     "Connection: close\r\n\r\n#{body}")
      end

      def route(method, path, headers, body)
        case [method, path]
        when %w[GET /oauth/token]
          @oauth_token_endpoint ? [200, 'supported'] : not_found(method, path)
        when %w[POST /oauth/token]
          @oauth_token_endpoint ? oauth_exchange(parse(body)) : not_found(method, path)
        when %w[POST /auth/token] then legacy_exchange(parse(body))
        when %w[POST /graphql] then graphql(parse(body), headers['authorization'])
        else not_found(method, path)
        end
      end

      def not_found(method, path)
        [404, "<!DOCTYPE html><html><body><pre>Cannot #{method} #{path}</pre></body></html>"]
      end

      def parse(body)
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      def oauth_exchange(params)
        unless %w[appId accessCode codeVerifier].all? { |key| params[key].is_a?(String) }
          return record(:oauth_token, [400, { 'error' => 'Invalid request body' }])
        end

        record(:oauth_token, redeem(params) do |code|
          next 'The access code was created for a legacy flow.' unless code[:hash_algorithm]

          challenge = [Digest::SHA256.digest(params['codeVerifier'])].pack('m0').tr('+/', '-_').delete('=')
          challenge == code[:challenge] ? nil : challenge_mismatch
        end)
      end

      def legacy_exchange(params)
        return record(:auth_token, [401, { 'err' => 'App Id is required.' }]) unless params['appId']
        return record(:auth_token, [401, { 'err' => 'Challenge is required.' }]) unless params['challenge']

        record(:auth_token, redeem(params) do |code|
          next 'The access code was created for a pkce flow.' if code[:hash_algorithm]

          params['challenge'] == code[:challenge] ? nil : challenge_mismatch
        end)
      end

      def challenge_mismatch
        'Code challenge mismatch. Ensure the same challenge is used for authentication and token exchange.'
      end

      # Codes are single use: the server deletes a code before checking its challenge.
      def redeem(params)
        code = @lock.synchronize { @codes.delete(params['accessCode']) }
        return [401, { 'err' => 'Access code not found.' }] unless code
        return [401, { 'err' => 'Invalid request: application id does not match.' }] unless params['appId'] == APP_ID

        problem = yield(code)
        return [401, { 'err' => problem }] if problem

        tokens = @lock.synchronize do
          issued = @tokens_to_issue.shift || raise('the test did not provide enough tokens')
          @issued_tokens << issued['token']
          issued
        end
        [200, tokens]
      end

      def record(endpoint, response)
        @lock.synchronize { @exchanges << Exchange.new(endpoint, response[0]) }
        response
      end

      def graphql(params, authorization)
        query = params['query'].to_s
        if query.include?('app(id')
          app = params.dig('variables', 'id') == APP_ID && @connector_app ? { 'id' => APP_ID } : nil
          return [200, { 'data' => { 'app' => app } }]
        end

        token = authorization.to_s.sub(/\ABearer /, '')
        unless @lock.synchronize { @issued_tokens.include?(token) }
          return [403, { 'errors' => [{ 'message' => 'Your token is not valid.' }] }]
        end

        [200, { 'data' => { 'activeUser' => @user, 'serverInfo' => server_info } }]
      end
    end
  end
end
