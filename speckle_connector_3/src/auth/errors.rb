# frozen_string_literal: true

module SpeckleConnector3
  module Auth
    MINIMUM_SERVER_VERSION = '2.31.0'

    # Base of every way a browser sign-in attempt can end without a saved account.
    class AuthenticationError < StandardError; end

    # The attempt was cancelled, or replaced by a newer attempt.
    class AuthenticationCancelledError < AuthenticationError
      def initialize(message = 'Sign-in was cancelled.')
        super
      end
    end

    # The user declined access on the server's authorization page.
    class AccessDeniedError < AuthenticationError
      def initialize(message = 'Sign-in was declined in the browser.')
        super
      end
    end

    # The browser did not hand back an access code before the attempt's deadline.
    class AuthenticationTimeoutError < AuthenticationError
      def initialize(timeout_seconds)
        super("Sign-in timed out after #{format('%g', timeout_seconds / 60.0)} minutes without a response " \
              'from the browser. Please try again.')
      end
    end

    # The server does not register the connector sign-in app, which public servers ship from 2.31.0.
    class AuthAppUnavailableError < AuthenticationError
      def initialize(server_url, app_id)
        super("#{server_url} does not offer the Speckle connector sign-in app (#{app_id}). Signing in from " \
              "SketchUp needs Speckle server #{MINIMUM_SERVER_VERSION} or later; ask your server administrator " \
              'to upgrade the server.')
      end
    end

    # The server refused to exchange the access code for a token.
    class TokenExchangeRejectedError < AuthenticationError; end

    # The server could not be reached or did not answer like a Speckle server.
    class ServerRequestError < AuthenticationError; end

    # The server URL is not an absolute http(s) URL.
    class InvalidServerUrlError < AuthenticationError
      def initialize(server_url)
        super("'#{server_url}' is not a valid server address. Use the full address, e.g. https://app.speckle.systems.")
      end
    end
  end
end
