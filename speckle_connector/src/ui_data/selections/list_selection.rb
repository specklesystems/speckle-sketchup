# frozen_string_literal: true

require_relative 'selection'

module SpeckleConnector
  module UiData
    module Selections
      # Selections data for UI.
      class ListSelection < Selection
        # @return [Hash{Symbol=>ListSelectionItem}, Hash{Symbol=>ListSelection}] items of the selection.
        attr_reader :items

        # @return [Array<Symbol>] selected items of the selection.
        attr_reader :selected_items

        # @return [Boolean] whether is multiple selection or not.
        attr_reader :multiple_selection

        def initialize(id, name, items, selected_items, multiple_selection)
          super(id, name)
          @items = items
          @selected_items = selected_items
          @multiple_selection = multiple_selection
          self[:items] = items
          self[:selectedItems] = selected_items
          self[:multipleSelection] = multiple_selection
        end
      end
    end
  end
end
