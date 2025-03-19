# frozen_string_literal: true

require_relative '../action'
require_relative '../../cards/send_card'
require_relative '../../cards/receive_card'
require_relative '../../filters/send/everything_filter'
require_relative '../../filters/send/selection_filter'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Action to remove cards.
    class RemoveModels < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        data.each do |model_card|
          SketchupModel::Dictionary::ModelCardDictionaryHandler.remove_card_dict(state.sketchup_state.sketchup_model, model_card)
          new_speckle_state = if model_card['typeDiscriminator'] == 'ReceiverModelCard'
                                state.speckle_state.without_receive_card(model_card['id'])
                              else
                                state.speckle_state.without_send_card(model_card['id'])
                              end
          state = state.with_speckle_state(new_speckle_state)
        end

        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('removeModels', js_script)
      end
    end
  end
end
