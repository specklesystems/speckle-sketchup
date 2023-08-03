# frozen_string_literal: true

require_relative '../filters/send/selection_filter'
require_relative '../filters/send/everything_filter'
require_relative '../filters/send/layer_filter'
require_relative '../ui_data/components/selections/list_selection'
require_relative '../ui_data/components/selections/list_selection_item'
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
          UiData::Components::Selections::ListSelectionItem.new(
            layer.persistent_id, layer.display_name, SpeckleObjects::Other::Color.to_rgb(layer.color), ''
          )
        end
        tags = Filters::Send::LayerFilter.new(layer_items, layer_items.collect(&:name))

        send_filter_items = [everything, selection, tags]

        # UiData::Selections::ListSelection.new('sendFilters', 'Send Filters',
        #                                       send_filter_items, [send_filter_items.keys.first], false)
        send_filter_items
      end

      def self.get_filters_from_model(filters)
        filters_objects = filters['items'].collect do |filter_key, filter|
          from_json = TYPE_CLASSES[filter_key.to_sym].method(:from_json)
          [filter_key, from_json.call(filter)]
        end.to_h
        UiData::Components::Selections::ListSelection.new(filters['id'], filters['name'],
                                              filters_objects, filters['selectedItems'], filters['multipleSelection'])
      end
    end
  end
end
