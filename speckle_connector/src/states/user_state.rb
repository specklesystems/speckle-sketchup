# frozen_string_literal: true

module SpeckleConnector
  module States
    # User specific states.
    class UserState
      # @return [Hash{Symbol => Object}] user specific preferences
      attr_reader :preferences

      def initialize(preferences)
        @preferences = preferences
      end
    end
  end
end
