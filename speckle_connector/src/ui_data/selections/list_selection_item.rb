# frozen_string_literal: true

module SpeckleConnector
  module UiData
    module Selections
      # Item of the list selection data for UI.
      class ListSelectionItem < Hash
        # @return [String] id of the selection item.
        attr_reader :id

        # @return [String] name of the selection item.
        attr_reader :name

        # @return [String, NilClass] color of the selection item.
        attr_reader :color

        def initialize(id, name, color)
          super()
          @id = id
          @name = name
          @color = color
          self[:id] = id
          self[:name] = name
          self[:color] = color unless color.nil?
        end
      end
    end
  end
end
