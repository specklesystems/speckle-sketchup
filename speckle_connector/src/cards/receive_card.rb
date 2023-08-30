# frozen_string_literal: true

require_relative 'card'

module SpeckleConnector
  module Cards
    # Receive card for sketchup connector to communicate speckle.
    class ReceiveCard < Card
      attr_reader :type_discriminator

      # @return [String, NilClass] message to send
      attr_reader :message

      # @return [String] object id to receive
      attr_reader :object_id

      # @return [String] name of the project
      attr_reader :project_name

      # @return [String] name of the model
      attr_reader :model_name

      def initialize(card_id, account_id, project_id, project_name, model_id, model_name, object_id)
        super(card_id, account_id, project_id, model_id)
        @object_id = object_id
        self[:object_id] = object_id
        self[:model_name] = model_name
        self[:project_name] = project_name
        @model_name = model_name
        @project_name = project_name
        @type_discriminator = 'ReceiverModelCard'
        self[:type_discriminator] = @type_discriminator
      end
    end
  end
end
