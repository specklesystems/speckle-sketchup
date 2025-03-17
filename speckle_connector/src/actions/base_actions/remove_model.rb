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
    # Action to remove send card.
    class RemoveModel < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        SketchupModel::Dictionary::ModelCardDictionaryHandler.remove_card_dict(state.sketchup_state.sketchup_model, data)
        new_speckle_state = if data['typeDiscriminator'] == 'ReceiverModelCard'
                              state.speckle_state.without_receive_card(data['id'])
                            else
                              state.speckle_state.without_send_card(data['id'])
                            end
        state = state.with_speckle_state(new_speckle_state)
        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('removeModel', js_script)
      end
    end
  end
end
