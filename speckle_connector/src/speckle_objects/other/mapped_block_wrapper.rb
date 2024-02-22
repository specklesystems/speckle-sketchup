# frozen_string_literal: true

require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # MappedBlockWrapper object definition for Speckle.
      class MappedBlockWrapper < Base
        SPECKLE_TYPE = 'Objects.Other.MappedBlockWrapper'
        def initialize(category:, units:, instance:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:category] = category
          self[:units] = units
          self[:instance] = instance
        end
      end
    end
  end
end
