# frozen_string_literal: true

require_relative '../base'

module SpeckleConnector
  module SpeckleObjects
    module Relations
      class Layer < Base
        SPECKLE_TYPE = 'Objects.Relations.Layer'

        def initialize(name:, color:, visible:, layers: [], application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:name] = name
          self[:color] = color
          self[:visible] = visible
          self[:layers] = layers if layers.any?
        end
      end
    end
  end
end
