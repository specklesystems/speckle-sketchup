# frozen_string_literal: true

require_relative '../immutable/immutable'

module SpeckleConnector
  module States
    # User specific states.
    class UserState
      include Immutable::ImmutableUtils

      # @return [Hash{Symbol => Object}] user specific preferences
      attr_reader :preferences

      def initialize(preferences)
        @preferences = preferences
      end
    end
  end
end
