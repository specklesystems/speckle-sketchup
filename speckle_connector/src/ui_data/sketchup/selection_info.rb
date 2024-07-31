# frozen_string_literal: true

module SpeckleConnector3
  module UiData
    module Sketchup
      class SelectionInfo < Hash
        def initialize(selected_object_ids, summary)
          super()
          self[:selectedObjectIds] = selected_object_ids
          self[:summary] = summary
        end
      end
    end
  end
end
