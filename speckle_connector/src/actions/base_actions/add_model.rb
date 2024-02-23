# frozen_string_literal: true

require_relative '../action'
require_relative '../../cards/send_card'
require_relative '../../cards/receive_card'
require_relative '../../filters/send/everything_filter'
require_relative '../../filters/send/selection_filter'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Action to add send card.
    class AddModel < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        if data['typeDiscriminator'] == 'ReceiverModelCard'
          receive_card = Cards::ReceiveCard.new(data['modelCardId'], data['accountId'],
                                                data['projectId'], data['projectName'],
                                                data['modelId'], data['modelName'],
                                                data['referencedObject'])
          SketchupModel::Dictionary::ModelCardDictionaryHandler
            .save_card_to_model(receive_card, state.sketchup_state.sketchup_model)
          new_speckle_state = state.speckle_state.with_receive_card(receive_card)
          state = state.with_speckle_state(new_speckle_state)
          js_script = "baseBinding.receiveResponse('#{resolve_id}')"
          return state.with_add_queue_js_command('addSendCard', js_script)
        end

        send_filter = Filters::SendFilters.get_filter_from_ui_data(data['sendFilter'])
        # Init card and add to the state
        send_card = Cards::SendCard.new(data['modelCardId'], data['accountId'], data['projectId'], data['modelId'],
                                        send_filter, {})

        SketchupModel::Dictionary::ModelCardDictionaryHandler
          .save_card_to_model(send_card, state.sketchup_state.sketchup_model)

        new_speckle_state = state.speckle_state.with_send_card(send_card)
        state = state.with_speckle_state(new_speckle_state)
        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('addSendCard', js_script)
      end
    end
  end
end
