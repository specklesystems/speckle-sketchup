# frozen_string_literal: true

require_relative '../action'
require_relative '../../cards/send_card'
require_relative '../../filters/send/everything_filter'
require_relative '../../filters/send/selection_filter'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/send_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Action to update model card.
    class UpdateModel < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        # Init card and add to the state
        send_card = Cards::SendCard.new(data['id'], data['accountId'], data['projectId'], data['modelId'],
                                        data['sendFilter'], {})

        SketchupModel::Dictionary::SendCardDictionaryHandler
          .save_card_to_model(send_card, state.sketchup_state.sketchup_model)
        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('updateSendCard', js_script)
      end
    end
  end
end
