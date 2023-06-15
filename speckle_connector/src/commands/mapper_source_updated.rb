# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/mapper_source_updated'

module SpeckleConnector
  module Commands
    # Command to update mapper source.
    class MapperSourceUpdated < Command
      def _run(data)
        stream_id = data['stream_id']
        base = data['base']
        branch_name = data['branch_name']
        branch_id = data['branch_id']
        stream_name = data['stream_name']
        action = Actions::MapperSourceUpdated.new(stream_id, base, stream_name, branch_name, branch_id)
        app.update_state!(action)
      end
    end
  end
end
