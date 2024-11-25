# frozen_string_literal: true

require_relative '../action'
require_relative '../../convertors/to_native'
require_relative '../../convertors/to_native_v2'

module SpeckleConnector3
  module Actions
    # After objects send to server.
    class AfterSendObjects < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id, referenced_object_id)
        model_card = state.speckle_state.send_cards[model_card_id]
        account = Accounts.get_account_by_id(model_card.account_id)
        args = {
            modelCardId: model_card_id,
            projectId: model_card.project_id,
            modelId: model_card.model_id,
            token: account['token'],
            serverUrl: account['serverInfo']['url'],
            accountId: model_card.account_id,
            message: model_card.message,
            referencedObjectId: referenced_object_id,
            sendConversionResults: state.speckle_state.conversion_results[model_card_id]
        }

        after_send_object_js_script = "sendBinding.emit('createVersionViaBrowser', #{args.to_json})"
        state = state.with_add_queue_js_command('createVersionViaBrowser', after_send_object_js_script)

        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('afterSendObject', resolve_js_script)
      end
    end
  end
end
