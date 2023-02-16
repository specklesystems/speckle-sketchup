# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Action to collect versions from sketchup and connector to track user's version by mixpanel.
    class CollectVersions < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _data)
        versions = {
          sketchup: Sketchup.version.to_i,
          speckle: SpeckleConnector::CONNECTOR_VERSION
        }
        state.with_add_queue('collectVersions', versions.to_json, [])
      end
    end
  end
end
