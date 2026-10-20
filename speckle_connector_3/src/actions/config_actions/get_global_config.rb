# frozen_string_literal: true

require 'json'
require_relative '../action'
require_relative '../../settings/global_config'

module SpeckleConnector3
  module Actions
    # Action to get machine-wide global config.
    class GetGlobalConfig < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        config = Settings::GlobalConfig.new.to_h
        js_script = "configBinding.receiveResponse('#{resolve_id}', #{config.to_json})"
        state.with_add_queue_js_command('getGlobalConfig', js_script)
      end
    end
  end
end
