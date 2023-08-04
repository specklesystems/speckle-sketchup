# frozen_string_literal: true

require_relative '../action'
require_relative '../../cards/send_card_multiple_filters'
require_relative '../../filters/send/everything_filter'
require_relative '../../filters/send/selection_filter'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/send_card_dictionary_handler'

module SpeckleConnector
  module Actions
    # Action to add send card.
    class AddSendCard < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        puts "Send Card: #{data}"
        # TODO: Later we will need unique id for each card.
        card_id = "#{data['accountId']}-#{data['projectId']}-#{data['modelId']}"
        puts card_id
        puts data['filters'].to_json
        filters = Filters::SendFilters.get_default(state.sketchup_state.sketchup_model)
        # Init card and add to the state
        send_card = Cards::SendCardMultipleFilters.new(card_id, data['accountId'], data['projectId'], data['modelId'], filters)

        SketchupModel::Dictionary::SendCardDictionaryHandler
          .save_card_to_model(send_card, state.sketchup_state.sketchup_model)

        new_speckle_state = state.speckle_state.with_send_card(send_card)
        state = state.with_speckle_state(new_speckle_state)
        # Resolve promise
        js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('addSendCard', js_script)
      end
    end
  end
end
