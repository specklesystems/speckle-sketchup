# frozen_string_literal: true

require_relative '../action'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Gets model state.
    class GetModelState < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        send_cards_hash = SketchupModel::Dictionary::ModelCardDictionaryHandler
                          .get_cards_from_dict(state.sketchup_state.sketchup_model)

        send_cards = send_cards_hash.collect do |id, card|
          filters = Filters::SendFilters.get_filters_from_model(card['filters'])
          send_card = Cards::SendCard.new(id, card['account_id'], card['project_id'], card['model_id'], filters)

          new_speckle_state = state.speckle_state.with_send_card(send_card)
          state = state.with_speckle_state(new_speckle_state)
          {
            accountId: send_card.account_id,
            projectId: send_card.project_id,
            modelId: send_card.model_id,
            filters: send_card.filters
          }
        end

        model_state = { sendCards: send_cards }

        js_script = "baseBinding.receiveResponse('#{resolve_id}', #{model_state.to_json})"
        state.with_add_queue_js_command('getModelState', js_script)
      end
    end
  end
end
