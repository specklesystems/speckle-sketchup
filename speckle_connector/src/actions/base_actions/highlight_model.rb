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
                                 state.speckle_state.receive_cards[model_card_id].receive_result.baked_object_ids
                               else
                                 state.speckle_state.send_cards[model_card_id].send_filter.selected_object_ids
                               end

        state.sketchup_state.sketchup_model.selection.clear

        # Flat entities to select entities on card
        flat_entities = SketchupModel::Query::Entity.flat_entities(state.sketchup_state.sketchup_model.entities)

        flat_entities.each do |entity|
          next unless objects_to_highlight.include?(entity.persistent_id)

          if entity.is_a?(Sketchup::ComponentDefinition)
            state.sketchup_state.sketchup_model.selection.add(entity.instances)
          end
          state.sketchup_state.sketchup_model.selection.add(entity)
        end

        state.sketchup_state.sketchup_model.active_view.zoom(state.sketchup_state.sketchup_model.selection)

        # Resolve promise
        js_script = "baseBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('highlightModel', js_script)
      end
    end
  end
end
