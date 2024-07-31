# frozen_string_literal: true

module SpeckleConnector3
  module UiData
    module Components
      module Selections
        # Item of the list selection data for UI.
        class ListSelectionItem < Hash
          # @return [String] id of the selection item.
          attr_reader :id

          # @return [String] name of the selection item.
          attr_reader :name

          # @return [String, NilClass] color of the selection item.
          attr_reader :color

          # @return [String] summary of the selection item.
          attr_reader :summary

          def initialize(id, name, color, summary)
            super()
            @id = id
            @name = name
            @color = color
            @summary = summary
            self[:id] = id
            self[:name] = name
            self[:color] = color unless color.nil?
            self[:summary] = summary
          end
        end
      end
    end
  end
end
