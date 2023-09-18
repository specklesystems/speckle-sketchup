# frozen_string_literal: true

require_relative '../action'
require_relative '../../cards/send_card'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Add model to document state.
    class AddModelToDocumentState < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model)
        puts model.to_json

        send_filter = Filters::SendFilters.get_filter_from_ui_data(model['sendFilter'])

        send_card = Cards::SendCard.new(model['id'], model['accountId'], model['projectId'], model['modelId'], send_filter, {})
        SketchupModel::Dictionary::ModelCardDictionaryHandler
          .save_card_to_model(send_card, state.sketchup_state.sketchup_model)
        new_speckle_state = state.speckle_state.with_send_card(send_card)
        state = state.with_speckle_state(new_speckle_state)

        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('addModelToDocumentState', js_script)
      end
    end
  end
end
