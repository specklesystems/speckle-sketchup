# frozen_string_literal: true

require_relative 'action'

module SpeckleConnector
  module Actions
    # Action to update mapper source.
    class MapperSourceUpdated < Action
      def initialize(stream_id, base, stream_name, branch_name, branch_id)
        super()
        @stream_id = stream_id
        @base = base
        @stream_name = stream_name
        @branch_name = branch_name
        @branch_id = branch_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        levels = @base['@Levels'].to_json
        types = @base['@Types'].to_json
        state.with_add_queue('mapperSourceUpdated', @stream_id, [
                               { is_string: false, val: levels },
                               { is_string: false, val: types }
                             ])
      end
    end
  end
end
