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
        # objects_to_highlight = if data['typeDiscriminator'] == 'ReceiverModelCard'
        #                          # model_card = state.speckle_state.receive_cards[model_card_id]
        #                          # TODO: return received objects
        #                          []
        #                        else
        #                          model_card = state.speckle_state.send_cards[model_card_id]
        #                          model_card.send_filter.selected_object_ids
        #                        end
        objects_to_highlight = state.speckle_state.send_cards[model_card_id].send_filter.selected_object_ids

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
