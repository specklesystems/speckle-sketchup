# frozen_string_literal: true

require_relative '../action'
require_relative '../../sketchup_model/dictionary/send_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Action to check send card expirations.
    class SendCardExpirationCheck < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        return state unless state.speckle_state.changed_entity_ids.any?

        expired_send_cards_ids = state.speckle_state.send_cards.select do |_id, send_card|
          send_card.send_filter.check_expiry(state.speckle_state.changed_entity_ids)
        end.keys.to_a
        js_script = "sendBinding.emit('sendersExpired', #{expired_send_cards_ids.to_json})"
        state.with_add_queue_js_command('sendersExpired', js_script)
      end
    end
  end
end
