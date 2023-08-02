# frozen_string_literal: true

require_relative '../filters/send/selection_filter'
require_relative '../filters/send/everything_filter'
require_relative '../filters/send/layer_filter'
require_relative '../ui_data/selections/list_selection'
require_relative '../ui_data/selections/list_selection_item'
require_relative '../speckle_objects/other/color'

module SpeckleConnector
  module Filters
    # Send filters for sketchup connector.
    class SendFilters
      TYPE_CLASSES = {
        'everything': Filters::Send::EverythingFilter,
        'selection': Filters::Send::SelectionFilter,
        'tags': Filters::Send::LayerFilter
      }.freeze

      # Get default send filters.
      # @param sketchup_model [Sketchup::Model] active model.
      def self.get_default(sketchup_model)
        everything = Filters::Send::EverythingFilter.new
        selection = Filters::Send::SelectionFilter.new
        layer_items = sketchup_model.layers.collect do |layer|
          [layer.persistent_id, UiData::Selections::ListSelectionItem.new(
            layer.persistent_id, layer.display_name, SpeckleObjects::Other::Color.to_rgb(layer.color)
          )]
        end.to_h
        tags = Filters::Send::LayerFilter.new(layer_items, layer_items.keys)

        send_filter_items = [everything, selection, tags].collect do |item|
          [item.id, item]
        end.to_h

        UiData::Selections::ListSelection.new('sendFilters', 'Send Filters',
                                              send_filter_items, [send_filter_items.keys.first], false)
      end
    end
  end
end
