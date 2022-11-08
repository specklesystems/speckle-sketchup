# frozen_string_literal: true

module SpeckleConnector
  module States
    # State of the speckle on ruby.
    class SpeckleState
      attr_reader :accounts

      def initialize(accounts)
        @accounts = accounts
      end
    end
  end
end
