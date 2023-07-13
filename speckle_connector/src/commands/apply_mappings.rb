# frozen_string_literal: true

require_relative 'command'
require_relative '../actions/apply_mappings'

module SpeckleConnector
  module Commands
    # Command to apply mapping for selected entities.
    class ApplyMappings < Command
      def _run(_resolve_id, data)
        entities_to_map = data['entitiesToMap']
        method = data['method']
        category = data['category']
        family = data['family']
        family_type = data['familyType']
        level = data['level']
        name = data['name']
        is_definition = data['isDefinition']
        action = Actions::ApplyMappings.new(entities_to_map, method, category, family,
                                            family_type, level, name, is_definition)
        app.update_state!(action)
      end
    end
  end
end
