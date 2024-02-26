# frozen_string_literal: true

require_relative 'card'

module SpeckleConnector
  module Cards
    # Send card for sketchup connector to communicate speckle.
    class SendCard < Card
      # @return [Filters::Send::EverythingFilter | Filters::Send::SelectionFilter | Filters::Send::LayerFilter] filter of the card.
      attr_reader :send_filter

      # @return [Object] send settings of the card.
      attr_reader :send_settings

      attr_reader :type_discriminator

      # @return [String, NilClass] message to send
      attr_reader :message

      def initialize(model_card_id, account_id, project_id, model_id, send_filter, send_settings)
        super(model_card_id, account_id, project_id, model_id)
        @send_filter = send_filter
        @send_settings = send_settings
        @type_discriminator = 'SenderModelCard'
        self[:sendFilter] = send_filter
        self[:sendSettings] = send_settings
        self[:type_discriminator] = @type_discriminator
      end
    end
  end
end
