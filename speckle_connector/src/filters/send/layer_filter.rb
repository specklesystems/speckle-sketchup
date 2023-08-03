# frozen_string_literal: true

require_relative '../../ui_data/components/selections/list_selection'

module SpeckleConnector
  module Filters
    module Send
      # Layer (tag) filter for sketchup connector to send all.
      class LayerFilter < UiData::Components::Selections::ListSelection
        def initialize(items, selected_items)
          super('tags', 'Tags', items, selected_items, true)
        end

        def self.from_json(data)
          items = data['items'].collect do |key, item|
            [key, [UiData::Components::Selections::ListSelectionItem.new(item['id'], item['name'], item['color'], '')]]
          end.to_h
          LayerFilter.new(items, data['selectedItems'])
        end
      end
    end
  end
end
