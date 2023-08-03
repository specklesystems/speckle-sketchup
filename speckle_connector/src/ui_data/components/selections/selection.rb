# frozen_string_literal: true

module SpeckleConnector
  module UiData
    module Components
      module Selections
        # Selections data for UI.
        class Selection < Hash
          # @return [String] id of the selection.
          attr_reader :id

          # @return [String] name of the selection.
          attr_reader :name

          def initialize(id, name)
            super()
            @id = id
            @name = name
            self[:id] = id
            self[:name] = name
          end
        end
      end
    end
  end
end
