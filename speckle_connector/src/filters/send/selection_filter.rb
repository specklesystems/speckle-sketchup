# frozen_string_literal: true

require_relative '../../ui_data/components/selections/list_selection_item'

module SpeckleConnector
  module Filters
    module Send
      # Selection filter for sketchup connector to send all.
      class SelectionFilter < UiData::Components::Selections::ListSelectionItem
        def initialize
          super('selection', 'Selection', nil,
                'User based selection filter. UI should replace this summary with the selection info summary!')
        end

        def self.from_json(_data)
          SelectionFilter.new
        end
      end
    end
  end
end
