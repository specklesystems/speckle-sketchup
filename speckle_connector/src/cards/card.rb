# frozen_string_literal: true

require_relative '../speckle_objects/other/color'

module SpeckleConnector
  module Cards
    # Card for sketchup connector to communicate speckle.
    class Card < Hash
      # @return [String] id of the card.
      attr_reader :model_card_id

      # @return [String] account id of the card.
      attr_reader :account_id

      # @return [String] project id of the card.
      attr_reader :project_id

      # @return [String] model id of the card.
      attr_reader :model_id

      # @return [Boolean] card is valid or not.
      attr_reader :valid

      def initialize(model_card_id, account_id, project_id, model_id)
        super()
        @model_card_id = model_card_id
        @account_id = account_id
        @project_id = project_id
        @model_id = model_id
        @valid = true
        self[:model_card_id] = model_card_id
        self[:account_id] = account_id
        self[:project_id] = project_id
        self[:model_id] = model_id
        self[:valid] = @valid
      end
    end
  end
end
