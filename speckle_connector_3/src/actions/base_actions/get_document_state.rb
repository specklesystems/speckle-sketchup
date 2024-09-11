# frozen_string_literal: true

require_relative '../action'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Gets document state.
    class GetDocumentState < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        send_cards_hash = SketchupModel::Dictionary::ModelCardDictionaryHandler
                          .get_send_cards_from_dict(state.sketchup_state.sketchup_model)

        # TODO: CONVERTER_V2: Extract into new actions
        send_cards = send_cards_hash.collect do |id, card|
          filter = Filters::SendFilters.get_filter_from_document(card['sendFilter'])
          settings = Settings::CardSetting.get_filter_from_document(card['sendSettings'])
          send_card = Cards::SendCard.new(
            id,
            card['account_id'],
            card['project_id'],
            card['project_name'],
            card['model_id'],
            card['model_name'],
            card['latest_created_version_id'],
            filter,
            settings
          )

          new_speckle_state = state.speckle_state.with_send_card(send_card)
          state = state.with_speckle_state(new_speckle_state)
          {
            modelCardId: send_card.model_card_id,
            accountId: send_card.account_id,
            projectId: send_card.project_id,
            modelId: send_card.model_id,
            sendFilter: send_card.send_filter,
            settings: send_card.send_settings,
            latestCreatedVersionId: send_card.latest_created_version_id,
            typeDiscriminator: send_card.type_discriminator
          }
        end

        receive_cards_hash = SketchupModel::Dictionary::ModelCardDictionaryHandler
                             .get_receive_cards_from_dict(state.sketchup_state.sketchup_model)

        # TODO: CONVERTER_V2: Extract into new actions
        receive_cards = receive_cards_hash.collect do |id, card|
          receive_card = Cards::ReceiveCard.new(id, card['account_id'], card['project_id'], card['model_id'],
                                                card['project_name'], card['model_name'], card['selected_version_id'],
                                                card['selected_version_source_app'], card['selected_version_user_id'],
                                                card['latest_version_id'], card['latest_version_source_app'],
                                                card['latest_version_user_id'], card['has_dismissed_update_warning'],
                                                card['expired'], card['baked_object_ids'])

          new_speckle_state = state.speckle_state.with_receive_card(receive_card)
          state = state.with_speckle_state(new_speckle_state)
          {
            modelCardId: receive_card.model_card_id,
            accountId: receive_card.account_id,
            projectId: receive_card.project_id,
            modelId: receive_card.model_id,
            projectName: receive_card.project_name,
            modelName: receive_card.model_name,
            selectedVersionId: receive_card.selected_version_id,
            selectedVersionSourceApp: receive_card.selected_version_source_app,
            selectedVersionUserId: receive_card.selected_version_user_id,
            latestVersionId: receive_card.latest_version_id,
            latestVersionSourceApp: receive_card.latest_version_source_app,
            latestVersionUserId: receive_card.latest_version_user_id,
            hasDismissedUpdateWarning: receive_card.has_dismissed_update_warning,
            expired: receive_card.expired,
            bakedObjectIds: receive_card.baked_object_ids,
            typeDiscriminator: receive_card.type_discriminator
          }
        end

        model_state = { models: send_cards + receive_cards }

        js_script = "baseBinding.receiveResponse('#{resolve_id}', #{model_state.to_json})"
        state.with_add_queue_js_command('getDocumentState', js_script)
      end
    end
  end
end
