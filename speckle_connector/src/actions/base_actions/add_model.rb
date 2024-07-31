# frozen_string_literal: true

require_relative 'add_send_model_card'
require_relative 'add_receive_model_card'
require_relative '../action'
require_relative '../../cards/send_card'
require_relative '../../cards/receive_card'
require_relative '../../filters/send/everything_filter'
require_relative '../../filters/send/selection_filter'
require_relative '../../filters/send_filters'
require_relative '../../sketchup_model/dictionary/model_card_dictionary_handler'

module SpeckleConnector3
  module Actions
    # Action to add send card.
    class AddModel < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, data)
        if data['typeDiscriminator'] == 'SenderModelCard'
          Actions::AddSendModelCard.update_state(state, resolve_id, data)
        else
          Actions::AddReceiveModelCard.update_state(state, resolve_id, data)
        end
      end
    end
  end
end
