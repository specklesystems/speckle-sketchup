# frozen_string_literal: true

require_relative 'card'

module SpeckleConnector3
  module Cards
    # Send card for sketchup connector to communicate speckle.
    class SendCardMultipleFilters < Card
      # @return [Hash{String=>Filter}] filters of the card.
      attr_reader :filters

      def initialize(card_id, account_id, project_id, model_id, filters)
        super(card_id, account_id, project_id, model_id)
        @filters = filters
        self[:filters] = filters
      end
    end
  end
end
