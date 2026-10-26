# frozen_string_literal: true

require 'json'
# rubocop:disable SketchupPerformance/OpenSSL
require 'net/http'
# rubocop:enable SketchupPerformance/OpenSSL
require 'uri'
require_relative 'errors'

module SpeckleConnector3
  module Auth
    # Short JSON requests to a Speckle server, bounded by explicit timeouts so a request thread that outlives its
    # sign-in attempt still ends.
    class HttpClient
      Response = Struct.new(:status, :body) do
        def ok?
          status.between?(200, 299)
        end

        # @return [Hash, nil] the parsed JSON object, nil when the body is not one
        def json
          parsed = JSON.parse(body.to_s)
          parsed.is_a?(Hash) ? parsed : nil
        rescue JSON::ParserError
          nil
        end
      end

      NETWORK_ERRORS = [SocketError, SystemCallError, IOError, Timeout::Error, Net::ProtocolError].freeze

      def initialize(open_timeout: 10, read_timeout: 20)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      # @return [Response]
      # @raise [ServerRequestError] when the server cannot be reached or does not answer in time
      def get(url)
        request(URI(url)) { |uri| Net::HTTP::Get.new(uri) }
      end

      # @return [Response]
      # @raise [ServerRequestError] when the server cannot be reached or does not answer in time
      def post_json(url, payload, headers = {})
        request(URI(url)) do |uri|
          post = Net::HTTP::Post.new(uri)
          post['Content-Type'] = 'application/json'
          headers.each { |name, value| post[name] = value }
          post.body = JSON.generate(payload)
          post
        end
      end

      private

      def request(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        response = http.start { |connection| connection.request(yield(uri)) }
        Response.new(response.code.to_i, response.body.to_s)
      rescue *NETWORK_ERRORS, OpenSSL::SSL::SSLError => e
        raise ServerRequestError,
              "Could not reach #{uri.scheme}://#{uri.host}:#{uri.port} (#{e.class.name}: #{e.message})."
      end
    end
  end
end
