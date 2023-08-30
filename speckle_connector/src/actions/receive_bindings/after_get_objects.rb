# frozen_string_literal: true

require_relative '../action'
require_relative '../../convertors/to_native'
require_relative '../../ext/TT_Lib2/progressbar'

module SpeckleConnector
  module Actions
    # Receive from server.
    class AfterGetObjects < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id, source_application, root_obj)
        model_card = state.speckle_state.receive_cards[model_card_id]
        converter = Converters::ToNative.new(state, model_card.model_id, model_card.project_name,
                                             model_card.model_name, source_application)
        # Have side effects on the sketchup model. It effects directly on the entities by adding new objects.
        state = converter.receive_commit_object(root_obj)


        resolve_js_script = "receiveBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('receive', resolve_js_script)
      end
    end
  end
end
