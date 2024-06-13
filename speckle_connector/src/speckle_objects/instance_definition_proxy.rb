# frozen_string_literal: true

require_relative 'base'

module SpeckleConnector
  module SpeckleObjects
    class InstanceDefinitionProxy < Base
      SPECKLE_TYPE = 'Speckle.Core.Models.Instances.InstanceDefinitionProxy'
      def initialize(objects, max_depth, application_id: nil)
        super(
          speckle_type: SPECKLE_TYPE,
          total_children_count: 0,
          application_id: application_id,
          id: nil
        )
        self[:Objects] = objects
        self[:MaxDepth] = max_depth
      end
    end
  end
end
