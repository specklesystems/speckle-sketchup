# frozen_string_literal: true

require_relative 'base'

module SpeckleConnector
  module SpeckleObjects
    class InstanceProxy < Base
      SPECKLE_TYPE = 'Speckle.Core.Models.Instances.InstanceProxy'
      def initialize(definition_id, transform, max_depth, application_id: nil)
        super(
          speckle_type: SPECKLE_TYPE,
          total_children_count: 0,
          application_id: application_id,
          id: nil
        )
        self[:DefinitionId] = definition_id
        self[:MaxDepth] = max_depth
        self[:Transform] = transform
      end
    end
  end
end
