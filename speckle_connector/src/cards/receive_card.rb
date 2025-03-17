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

      # @return [String] latest version id to receive
      attr_reader :latest_version_id

      # @return [Boolean] whether new version notification is dismissed or not
      attr_reader :has_dismissed_update_warning

      # @return [String] name of the project
      attr_reader :project_name

      # @return [String] name of the model
      attr_reader :model_name

      # @return [String] whether card is expired or not
      attr_reader :expired

      # @return [Array<Integer>] object ids that baked after receive.
      attr_reader :baked_object_ids

      def initialize(
        card_id,
        account_id,
        project_id,
        model_id,
        project_name,
        model_name,
        selected_version_id,
        latest_version_id,
        has_dismissed_update_warning,
        expired,
        baked_object_ids = nil
      )
        super(card_id, account_id, project_id, model_id)
        @selected_version_id = selected_version_id
        @latest_version_id = latest_version_id
        @has_dismissed_update_warning = has_dismissed_update_warning
        @baked_object_ids = baked_object_ids
        self[:selected_version_id] = selected_version_id
        self[:has_dismissed_update_warning] = has_dismissed_update_warning
        self[:latest_version_id] = latest_version_id
        self[:model_name] = model_name
        self[:project_name] = project_name
        self[:expired] = expired
        self[:baked_object_ids] = @baked_object_ids
        @expired = expired
        @model_name = model_name
        @project_name = project_name
        @type_discriminator = 'ReceiverModelCard'
        self[:type_discriminator] = @type_discriminator
      end
    end
  end
end
