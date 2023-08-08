# frozen_string_literal: true

require_relative '../action'
require_relative '../../filters/send_filters'

module SpeckleConnector
  module Actions
    # Action to get send filter.
    class GetSendFilters < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        default_filters = Filters::SendFilters.get_default(state.sketchup_state.sketchup_model)
        js_script = "sendBinding.receiveResponse('#{resolve_id}', #{default_filters.to_json})"
        state.with_add_queue_js_command('getSendFilter', js_script)
      end
    end
  end
end
