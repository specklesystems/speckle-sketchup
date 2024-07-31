# frozen_string_literal: true

require_relative 'selection'

module SpeckleConnector3
  module UiData
    module Components
      module Selections
        # Selections data for UI.
        class ListSelection < Selection
          # @return [Hash{Symbol=>ListSelectionItem}, Hash{Symbol=>ListSelection}] items of the selection.
          attr_reader :options

          # @return [Array<Symbol>] selected items of the selection.
          attr_reader :selected_options

          # @return [Boolean] whether is multiple selection or not.
          attr_reader :multiple_selection

          def initialize(id, name, options, selected_options, multiple_selection)
            super(id, name)
            @options = options
            @selected_options = selected_options
            @multiple_selection = multiple_selection
            self[:options] = options
            self[:selectedOptions] = selected_options
            self[:multipleSelection] = multiple_selection
          end
        end
      end
    end
  end
end
