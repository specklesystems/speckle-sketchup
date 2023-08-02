# frozen_string_literal: true

require_relative '../../ui_data/selections/list_selection_item'

module SpeckleConnector
  module Filters
    module Send
      # Selection filter for sketchup connector to send all.
      class SelectionFilter < UiData::Selections::ListSelectionItem
        def initialize
          super('selection', 'Selection', nil)
        end
      end
    end
  end
end
