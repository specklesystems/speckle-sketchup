# frozen_string_literal: true

require_relative '../../ui_data/selections/list_selection'

module SpeckleConnector
  module Filters
    module Send
      # Layer (tag) filter for sketchup connector to send all.
      class LayerFilter < UiData::Selections::ListSelection
        def initialize(items, selected_items)
          super('tags', 'Tags', items, selected_items, true)
        end
      end
    end
  end
end
