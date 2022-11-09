# frozen_string_literal: true

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleState
      attr_reader :accounts

      attr_reader :to_send

      def initialize(accounts, to_send)
        @accounts = accounts
        @to_send = to_send
      end
    end
  end
end
