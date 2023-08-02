# frozen_string_literal: true

require_relative '../action'
require_relative '../../sketchup_model/dictionary/send_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Action to activate send filter.
    class ActivateSendFilter < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data, value)
        SketchupModel::Dictionary::SendCardDictionaryHandler.update_filter(state.sketchup_state.sketchup_model, data, value)
        card_id = "#{data['accountId']}-#{data['projectId']}-#{data['modelId']}"
        send_card = state.speckle_state.send_cards[card_id]
        puts "Send card filter updated -> #{card_id} -> #{send_card}"
        js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('activateSendFilter', js_script)
      end
    end
  end
end
