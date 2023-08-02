# frozen_string_literal: true

require_relative '../action'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/send_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Gets model state.
    class GetModelState < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        send_cards_hash = SketchupModel::Dictionary::SendCardDictionaryHandler
                          .get_cards_from_dict(state.sketchup_state.sketchup_model)

        send_cards = send_cards_hash.collect do |_id, card|
          {
            accountId: card['account_id'],
            projectId: card['project_id'],
            modelId: card['model_id'],
            filters: card['filters']
          }
        end

        model_state = { sendCards: send_cards }

        js_script = "baseBinding.receiveResponse('#{resolve_id}', #{model_state.to_json})"
        state.with_add_queue_js_command('getModelState', js_script)
      end
    end
  end
end
