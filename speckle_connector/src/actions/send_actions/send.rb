# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../convertors/to_speckle'
require_relative '../../operations/send'
require_relative '../../ext/TT_Lib2/progressbar'
require_relative '../../ext/worker'

module SpeckleConnector
  module Actions
    # Send to server.
    class Send < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id)
        model_card = state.speckle_state.send_cards[model_card_id]
        account = Accounts.get_account_by_id(model_card.account_id)
        converter = Converters::ToSpeckle.new(state, model_card_id, model_card.send_filter)

        new_speckle_state, base = converter.convert_selection_to_base(state.user_state.preferences)
        id, total_children_count, batches, new_speckle_state = converter.serialize(base, new_speckle_state,
                                                                                   state.user_state.preferences)

        update_test(state)

        puts("converted #{base.count} objects for stream #{@stream_id}")

        state = state.with_speckle_state(new_speckle_state)

        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('send', resolve_js_script)
        args = {
          modelCardId: model_card_id,
          projectId: model_card.project_id,
          modelId: model_card.model_id,
          token: account['token'],
          serverUrl: account['serverInfo']['url'],
          accountId: model_card.account_id,
          message: model_card.message,
          sendObject: {
            id: id,
            totalChildrenCount: total_children_count,
            batches: batches
          }
        }
        js_script = "sendBinding.emit('sendViaBrowser', #{args.to_json})"
        state.with_add_queue_js_command('sendViaBrowser', js_script)
      end

      def self.update_test(state)
        dialog = UI::HtmlDialog.new(
          {
            :dialog_title => 'Dialog Example',
            :preferences_key => 'com.sample.plugin',
            :scrollable => true,
            :resizable => true,
            :width => 600,
            :height => 400,
            :left => 10,
            :top => 10,
            :min_width => 50,
            :min_height => 50,
            :max_width =>1000,
            :max_height => 1000,
            :style => UI::HtmlDialog::STYLE_DIALOG
          })
        html = '<div id="hi"><b>Hello world!</b></div>'
        dialog.set_html(html)
        dialog.show

        action = Proc.new do |status|
          js_command = "document.getElementById('hi').innerHTML = '<b>#{status}</b>'"
          log_js_command = "console.log('test')"
          dialog.execute_script(js_command)
          dialog.execute_script(log_js_command)
        end

        selected_object_ids = state.sketchup_state.sketchup_model.selection.collect(&:persistent_id)
        state.worker.add_jobs(1000.times.to_a.map { |i| Job.new(i, &action) })
        state.worker.do_work(Time.now.to_f, &action)
      end
    end
  end
end
