# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../convertors/to_speckle'
require_relative '../../operations/send'

module SpeckleConnector
  module Actions
    # Send to server.
    class Send < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id, account_id)
        model_card = state.speckle_state.send_cards[model_card_id]
        account = Accounts.get_account_by_id(account_id)
        converter = Converters::ToSpeckle.new(state, @stream_id)
        new_speckle_state, base = converter.convert_selection_to_base(state.user_state.preferences)
        id, total_children_count, batches, new_speckle_state = converter.serialize(base, new_speckle_state,
                                                                                   state.user_state.preferences)

        puts("converted #{base.count} objects for stream #{@stream_id}")

        state = state.with_speckle_state(new_speckle_state)

        selected_object_ids = state.sketchup_state.sketchup_model.selection.collect(&:persistent_id)
        selected_object_ids.each_with_index do |selection_id, i|
          sender_progress_args = {
            id: model_card_id,
            status: selection_id,
            progress: i
          }
          state.instant_message_sender.call("sendBinding.emit('senderProgress', #{sender_progress_args.to_json})")
        end

        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('send', resolve_js_script)
        args = {
          projectId: model_card.project_id,
          modelId: model_card.model_id,
          token: account['token'],
          serverUrl: account['serverInfo']['url'],
          accountId: model_card.account_id,
          sendObject: {
            id: id,
            totalChildrenCount: total_children_count,
            batches: batches
          }
        }
        js_script = "sendBinding.emit('sendViaBrowser', #{args.to_json})"
        state.with_add_queue_js_command('sendViaBrowser', js_script)
      end
    end
  end
end
