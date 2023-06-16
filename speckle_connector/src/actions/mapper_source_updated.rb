# frozen_string_literal: true

require_relative 'action'
require_relative '../mapper/mapper_source'

module SpeckleConnector
  module Actions
    # Action to update mapper source.
    class MapperSourceUpdated < Action
      def initialize(base, stream_id, commit_id)
        super()
        @base = base
        @stream_id = stream_id
        @commit_id = commit_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        levels = @base['@Levels'].to_json
        types = @base['@Types'].to_json
        mapper_source = Mapper::MapperSource.new(@stream_id, @commit_id, @base['@Levels'], @base['@Types'].to_h)
        new_speckle_state = state.speckle_state.with_mapper_source(mapper_source)
        state = state.with_speckle_state(new_speckle_state)

        state.with_add_queue('mapperSourceUpdated', @stream_id, [
                               { is_string: false, val: levels },
                               { is_string: false, val: types }
                             ])
      end
    end
  end
end
