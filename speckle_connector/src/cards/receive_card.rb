# frozen_string_literal: true

require_relative 'card'

module SpeckleConnector
  module Cards
    # Receive card for sketchup connector to communicate speckle.
    class ReceiveCard < Card
      attr_reader :type_discriminator

      # @return [String, NilClass] message to send
      attr_reader :message

      # @return [String] selected version id to receive
      attr_reader :selected_version_id

      # @return [String] name of the project
      attr_reader :project_name

      # @return [String] name of the model
      attr_reader :model_name

      # @return [String] whether card is expired or not
      attr_reader :expired

      def initialize(card_id, account_id, project_id, model_id, project_name, model_name, selected_version_id, expired)
        super(card_id, account_id, project_id, model_id)
        @selected_version_id = selected_version_id
        self[:selected_version_id] = selected_version_id
        self[:model_name] = model_name
        self[:project_name] = project_name
        self[:expired] = expired
        @expired = expired
        @model_name = model_name
        @project_name = project_name
        @type_discriminator = 'ReceiverModelCard'
        self[:type_discriminator] = @type_discriminator
      end
    end
  end
end
