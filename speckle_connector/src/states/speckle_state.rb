# frozen_string_literal: true

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleState
      # @return [Hash] accounts on appdata.
      attr_reader :accounts

      # @return [Hash] queue to send to server.
      attr_reader :to_send

      def initialize(accounts, to_send)
        @accounts = accounts
        @to_send = to_send
      end
    end
  end
end
