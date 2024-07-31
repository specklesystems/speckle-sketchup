# frozen_string_literal: true

require_relative '../immutable/immutable'

module SpeckleConnector3
  module States
    # User specific states.
    class UserState
      include Immutable::ImmutableUtils

      # @return [Immutable::Hash{Symbol => Object}] user specific preferences
      attr_reader :preferences

      def initialize(preferences)
        @preferences = preferences
      end

      def user_preferences
        @preferences[:user]
      end

      def model_preferences
        @preferences[:model]
      end

      def with_preferences(new_preferences)
        with(:@preferences => new_preferences)
      end
    end
  end
end
