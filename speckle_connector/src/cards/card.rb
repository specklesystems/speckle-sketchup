# frozen_string_literal: true

require_relative '../speckle_objects/other/color'

module SpeckleConnector3
  module Cards
    # Card for sketchup connector to communicate speckle.
    class Card < Hash
      # @return [String] id of the card.
      attr_reader :model_card_id

      # @return [String] account id of the card.
      attr_reader :account_id

      # @return [String] project name of the card.
      attr_reader :project_name

      # @return [String] project id of the card.
      attr_reader :project_id

      # @return [String] model id of the card.
      attr_reader :model_id

      # @return [String] model name of the card.
      attr_reader :model_name

      # @return [Boolean] card is valid or not.
      attr_reader :valid

      # rubocop:disable Metrics/ParameterLists
      def initialize(model_card_id, account_id, project_id, project_name, model_id, model_name)
        super()
        @model_card_id = model_card_id
        @account_id = account_id
        @project_id = project_id
        @project_name = project_name
        @model_id = model_id
        @model_name = model_name
        @valid = true
        self[:model_card_id] = model_card_id
        self[:account_id] = account_id
        self[:project_id] = project_id
        self[:project_name] = project_name
        self[:model_id] = model_id
        self[:model_name] = model_name
        self[:valid] = @valid
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
