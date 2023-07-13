# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/clear_mappings'

module SpeckleConnector
  module Commands
    # Command to clear mapping for selected entities.
    class ClearMappings < Command
      def _run(_resolve_id, data)
        entities_to_map = data['entitiesToClearMap']
        is_definition = data['isDefinition']
        action = Actions::ClearMappings.new(entities_to_map, is_definition)
        app.update_state!(action)
      end
    end
  end
end
