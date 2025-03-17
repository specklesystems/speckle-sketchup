# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/mapper_source_updated'

module SpeckleConnector
  module Commands
    # Command to update mapper source.
    class MapperSourceUpdated < Command
      def _run(_resolve_id, data)
        base = data['base']
        stream_id = data['stream_id']
        commit_id = data['commit_id']
        action = Actions::MapperSourceUpdated.new(base, stream_id, commit_id)
        app.update_state!(action)
      end
    end
  end
end
