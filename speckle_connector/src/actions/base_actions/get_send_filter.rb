# frozen_string_literal: true

require_relative '../action'

module SpeckleConnector
  module Actions
    # Action to get send filter.
    class GetSendFilter < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id)
        layer_tags = state.sketchup_state.sketchup_model.layers.collect do |layer|
          {
            id: layer.persistent_id,
            name: layer.display_name,
            active: true
          }
        end
        default_filters =
          {
            'everything': {
              name: 'Everything',
              input: 'toggle',
              duplicable: false,
              active: true
            },
            'selection': {
              name: 'Selection',
              input: 'toggle',
              duplicable: false,
              active: false
            },
            'tags': {
              name: 'Tags',
              input: 'toggle',
              active: false,
              duplicable: false,
              tags: layer_tags
            },
            'searchFilter': {
              name: 'Search',
              input: 'search',
              duplicable: true,
              active: false
            }
          }

        js_script = "baseBinding.receiveResponse('#{resolve_id}', #{default_filters.to_json})"
        state.with_add_queue_js_command('getSendFilter', js_script)
      end
    end
  end
end
