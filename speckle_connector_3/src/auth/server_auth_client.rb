# frozen_string_literal: true

require 'digest'
# rubocop:disable SketchupPerformance/OpenSSL
require 'securerandom'
# rubocop:enable SketchupPerformance/OpenSSL
require 'uri'
require_relative 'errors'

module SpeckleConnector3
  module Auth
    # The server side of the connector sign-in, as the .NET SDK and Archicad speak it: app `connectrV3`, an
    # access code bound to a PKCE challenge, the token exchange and the account details behind the token.
    class ServerAuthClient
      APP_ID = 'connectrV3'
      APP_SECRET = 'connectrV3'

      ACCOUNT_DETAILS_QUERY = 'query { activeUser { id name email company avatar } ' \
                              'serverInfo { name company description version migration { movedFrom movedTo } } }'
      USER_INFO_KEYS = %w[id name email company avatar].freeze
      APP_QUERY = 'query ($id: String!) { app(id: $id) { id } }'

      # One attempt's PKCE material. A fresh verifier per attempt keeps a code issued to another attempt unusable.
      Challenge = Struct.new(:verifier, :modern) do
        def self.generate(modern:)
          new(SecureRandom.urlsafe_base64(32, false), modern)
        end

        def code_challenge
          return verifier unless modern

          [Digest::SHA256.digest(verifier)].pack('m0').tr('+/', '-_').delete('=')
        end
      end

      attr_reader :server_url

      # @param server_url [String] absolute http(s) address of the server
      # @raise [InvalidServerUrlError]
      def initialize(server_url, http:)
        @server_url = self.class.normalize_url(server_url)
        @http = http
      end

      # @return [String] scheme, host, non-default port and path, without a trailing slash
      def self.normalize_url(server_url)
        uri = URI.parse(server_url.to_s.strip)
        raise InvalidServerUrlError, server_url unless uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty?

        port = uri.port == uri.default_port ? '' : ":#{uri.port}"
        "#{uri.scheme.downcase}://#{uri.host.downcase}#{port}#{uri.path}".sub(%r{/+\z}, '')
      rescue URI::InvalidURIError
        raise InvalidServerUrlError, server_url
      end

      # @raise [AuthAppUnavailableError] when the server predates the connector sign-in app
      # @raise [ServerRequestError]
      def ensure_app_registered
        data = graphql(APP_QUERY, { 'id' => APP_ID })
        raise AuthAppUnavailableError.new(server_url, APP_ID) unless data['app'].is_a?(Hash)
      end

      # Servers with the OAuth token endpoint answer GET /oauth/token with 200; older ones only have /auth/token.
      # @return [Challenge]
      def new_challenge
        modern = begin
          @http.get("#{server_url}/oauth/token").status == 200
        rescue ServerRequestError
          false
        end
        Challenge.generate(modern: modern)
      end

      def authorize_url(challenge)
        url = "#{server_url}/authn/verify/#{APP_ID}/#{challenge.code_challenge}"
        challenge.modern ? "#{url}?code_challenge_method=S256" : url
      end

      # @return [Hash] 'token' and 'refreshToken'
      # @raise [TokenExchangeRejectedError, ServerRequestError]
      def exchange(access_code, challenge)
        response = if challenge.modern
                     @http.post_json("#{server_url}/oauth/token",
                                     { appId: APP_ID, accessCode: access_code, codeVerifier: challenge.verifier })
                   else
                     @http.post_json("#{server_url}/auth/token",
                                     { appId: APP_ID, appSecret: APP_SECRET, accessCode: access_code,
                                       challenge: challenge.verifier })
                   end
        tokens = response.json
        return tokens if response.ok? && tokens && tokens['token'].is_a?(String) && !tokens['token'].empty?
        raise TokenExchangeRejectedError, exchange_failure_message(response) if response.status.between?(400, 499)

        raise ServerRequestError, "#{server_url} could not complete the sign-in (HTTP #{response.status})."
      end

      # Builds the account in the shape the .NET SDK writes into Accounts.db.
      # @return [Hash] account without 'isDefault', which the store decides
      # @raise [ServerRequestError]
      def account_for(tokens)
        data = graphql(ACCOUNT_DETAILS_QUERY, nil, 'Authorization' => "Bearer #{tokens['token']}")
        user = data['activeUser']
        server = data['serverInfo']
        unless user.is_a?(Hash) && server.is_a?(Hash) && user['email'].is_a?(String)
          raise ServerRequestError, "#{server_url} did not return the signed-in user's details."
        end

        {
          'id' => Digest::MD5.hexdigest(user['email'] + server_url).upcase,
          'token' => tokens['token'],
          'refreshToken' => tokens['refreshToken'],
          'isOnline' => true,
          'serverInfo' => server_info(server),
          'userInfo' => USER_INFO_KEYS.map { |key| [key, user[key]] }.to_h
        }
      end

      private

      def server_info(server)
        {
          'name' => server['name'],
          'company' => server['company'],
          'version' => server['version'],
          'description' => server['description'],
          'frontend2' => true,
          'url' => server_url,
          'migration' => server['migration']
        }
      end

      def graphql(query, variables, headers = {})
        payload = { query: query }
        payload[:variables] = variables if variables
        response = @http.post_json("#{server_url}/graphql", payload, headers)
        body = response.json
        return body['data'] if response.ok? && body && body['data'].is_a?(Hash)

        raise ServerRequestError, "#{server_url} did not answer as a Speckle server (HTTP #{response.status})."
      end

      def exchange_failure_message(response)
        reason = response.json && response.json['err']
        detail = reason.is_a?(String) ? ": #{reason[0, 200]}" : " (HTTP #{response.status})"
        "#{server_url} rejected the sign-in#{detail}. Please try again."
      end
    end
  end
end
