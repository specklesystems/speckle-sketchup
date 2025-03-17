# frozen_string_literal: true

require_relative '../action'
require_relative '../../sketchup_model/query/entity'

module SpeckleConnector
  module Actions
    # Action to add send card.
    class HighlightModel < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id)
        receiver_card = state.speckle_state.receive_cards[model_card_id]
        sender_card = state.speckle_state.send_cards[model_card_id]
        card = receiver_card || sender_card

        objects_to_highlight = if card.type_discriminator == 'ReceiverModelCard'
                                 state.speckle_state.receive_cards[model_card_id].baked_object_ids
                               else
                                 state.speckle_state.send_cards[model_card_id].send_filter.selected_object_ids
                               end

        SketchupModel::Utils::ViewUtils.highlight_entities(state.sketchup_state.sketchup_model, objects_to_highlight)

        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('highlightModel', js_script)
      end
    end
  end
end
