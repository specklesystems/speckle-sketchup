# frozen_string_literal: true

require_relative '../../speckle_objects/other/color'
require_relative '../../speckle_objects/color_proxy'

module SpeckleConnector3
  # Operations related to {SketchupModel}.
  module SketchupModel
    # Color related utilities.
    module Colors
      # Handle colors for layers.
      class ColorManager
        # @return [Hash{String=>SpeckleObjects::ColorProxy}] render material proxies.
        attr_reader :color_proxies

        def initialize
          @color_proxies = {}
        end

        # @param sketchup_model [Sketchup::Model] sketchup model to get colors from layers
        def unpack_colors(sketchup_model)
          sketchup_model.layers.each do |layer|
            value = SpeckleObjects::Other::Color.to_int(layer.color)
            if color_proxies[value.to_s].nil?
              color_proxies[value.to_s] = SpeckleObjects::ColorProxy.new(layer.color, value, [layer.persistent_id.to_s])
            else
              color_proxies[value.to_s].add_object_id(layer.persistent_id.to_s)
            end
          end

          color_proxies.values
        end
      end
    end
  end
end
