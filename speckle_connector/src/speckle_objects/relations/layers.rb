# frozen_string_literal: true

require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Relations
      class Layers < Base
        SPECKLE_TYPE = 'Objects.Relations.Layers'

        def initialize(active:, layers:)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: nil,
            id: nil
          )
          self[:active] = active
          self[:layers] = layers
        end
      end
    end
  end
end
