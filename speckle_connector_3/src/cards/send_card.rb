# frozen_string_literal: true

require_relative 'card'

module SpeckleConnector3
  module Cards
    # Send card for sketchup connector to communicate speckle.
    class SendCard < Card
      # @return [Filters::Send::EverythingFilter | Filters::Send::SelectionFilter | Filters::Send::LayerFilter] filter of the card.
      attr_reader :send_filter

      # @return [Array<Settings::CardSetting>] send settings of the card.
      attr_reader :send_settings

      attr_reader :type_discriminator

      # @return [String, NilClass] message to send
      attr_reader :message

      # @return [Boolean] whether sending is happening or not
      attr_reader :sending

      attr_reader :latest_created_version_id

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        model_card_id,
        account_id,
        server_url,
        workspace_id,
        workspace_slug,
        project_id,
        project_name,
        model_id,
        model_name,
        latest_created_version_id,
        send_filter,
        send_settings
      )
        super(model_card_id, account_id, server_url, workspace_id, workspace_slug, project_id, project_name, model_id, model_name)
        @send_filter = send_filter
        @send_settings = send_settings
        @latest_created_version_id = latest_created_version_id
        @type_discriminator = 'SenderModelCard'
        self[:sendFilter] = send_filter
        self[:sendSettings] = send_settings
        self[:latestCreatedVersionId] = latest_created_version_id
        self[:type_discriminator] = @type_discriminator
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
