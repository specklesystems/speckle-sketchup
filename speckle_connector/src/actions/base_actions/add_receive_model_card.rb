# frozen_string_literal: true

require_relative '../action'
require_relative '../../cards/send_card'
require_relative '../../cards/receive_card'
require_relative '../../cards/receive_result'
require_relative '../../filters/send/everything_filter'
require_relative '../../filters/send/selection_filter'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Action to add receive model card.
    class AddReceiveModelCard < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        model_card_id = data['modelCardId']
        account_id = data['accountId']
        project_id = data['projectId']
        model_id = data['modelId']
        project_name = data['projectName']
        model_name = data['modelName']
        expired = data['expired']
        selected_version_id = data['selectedVersionId']
        latest_version_id = data['latestVersionId']
        has_dismissed_update_warning = data['hasDismissedUpdateWarning']
        if data['receiveResult']
          receive_result = Cards::ReceiveResult.new(
            data['receiveResult']['bakedObjectIds'].values, # NOTE: IDK why UI sends it as object...
            data['receiveResult']['display']
          )
        end

        receive_card = Cards::ReceiveCard.new(model_card_id, account_id,
                                              project_id, model_id,
                                              project_name, model_name,
                                              selected_version_id, latest_version_id,
                                              has_dismissed_update_warning, expired, receive_result)
        SketchupModel::Dictionary::ModelCardDictionaryHandler
          .save_receive_card_to_model(receive_card, state.sketchup_state.sketchup_model)
        new_speckle_state = state.speckle_state.with_receive_card(receive_card)
        state = state.with_speckle_state(new_speckle_state)
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        return state.with_add_queue_js_command('addReceiveCard', js_script)
      end
    end
  end
end
