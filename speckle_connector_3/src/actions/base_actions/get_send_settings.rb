# frozen_string_literal: true

require_relative '../action'
require_relative '../../settings/card_settings'

module SpeckleConnector3
  module Actions
    # Action to get send settings.
    class GetSendSettings < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        # NOTE: below code is tested and works!
        # default_settings = [
        #   Settings::CardSetting.new(id: "includeAttributes", title: "Include Attributes", type: "boolean", value: true),
        #   Settings::CardSetting.new(id: "test", title: "Test", type: "string", value: "a", enum: %w[a b c])
        # ]
        default_settings = []
        js_script = "sendBinding.receiveResponse('#{resolve_id}', #{default_settings.to_json})"
        state.with_add_queue_js_command('getSendSettings', js_script)
      end
    end
  end
end
