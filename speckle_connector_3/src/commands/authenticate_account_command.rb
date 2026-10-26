# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/handle_error'
require_relative '../actions/account_actions/complete_authenticate_account'
require_relative '../auth/account_authenticator'
require_relative '../auth/sketchup_host'

module SpeckleConnector3
  module Commands
    # Starts a browser sign-in and returns without answering; the DUI's request is answered once the attempt
    # ends, from whichever of the call itself or a later timer tick ends it, exactly once per request id.
    class AuthenticateAccountCommand < Command
      # @param authenticator [Auth::AccountAuthenticator] shared by every call through this binding, so a new
      #   call replaces a pending one instead of finding the callback port busy
      def initialize(app, binding, authenticator: nil)
        super(app, binding)
        @action = Actions::CompleteAuthenticateAccount
        @authenticator = authenticator || Auth::AccountAuthenticator.new(
          browser: Auth::SketchupHost::Browser, scheduler: Auth::SketchupHost::Timers
        )
      end

      private

      def _run(resolve_id, server_url)
        @authenticator.authenticate(server_url) { |outcome| respond(resolve_id, outcome) }
      end

      def respond(resolve_id, outcome)
        if outcome.success?
          app.update_state!(@action, resolve_id, outcome.account)
        else
          respond_with_error(resolve_id, outcome.error)
        end
      rescue StandardError => e
        respond_with_error(resolve_id, e)
      end

      def respond_with_error(resolve_id, error)
        app.update_state!(Actions::HandleError.new(error, @binding.name, @action, [resolve_id]))
      end
    end
  end
end
