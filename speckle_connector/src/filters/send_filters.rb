# frozen_string_literal: true

require_relative '../speckle_objects/other/color'

module SpeckleConnector
  module Filters
    # Send filters for sketchup connector.
    class SendFilters
      # Get default send filters.
      # @param sketchup_model [Sketchup::Model] active model.
      def self.get_default(sketchup_model)
        layer_tags = sketchup_model.layers.collect do |layer|
          {
            id: layer.persistent_id, name: layer.display_name,
            color: SpeckleObjects::Other::Color.to_hex(layer.color), active: true
          }
        end
        {
          'everything': {
            name: 'Everything', input: 'toggle', duplicable: false
          },
          'selection': {
            name: 'Selection', input: 'toggle', duplicable: false
          },
          'tags': {
            name: 'Tags', input: 'toggle', duplicable: false, tags: layer_tags, activeTags: layer_tags
          },
          'searchFilter': {
            name: 'Search', input: 'search', duplicable: true
          }
        }.freeze
      end
    end
  end
end
