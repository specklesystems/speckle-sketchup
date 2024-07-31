# frozen_string_literal: true

require_relative 'color'

module SpeckleConnector3
  module SpeckleObjects
    module Other
      # Rendering options for scenes.
      class RenderingOptions
        # @param options [Sketchup::RenderingOptions] rendering options to convert speckle object
        def self.to_speckle(options)
          options.to_h.collect do |option_prop, option_value|
            speckle_value = if option_value.is_a?(Sketchup::Color)
                              Color.to_speckle(option_value)
                            else
                              option_value
                            end
            [option_prop.to_sym, speckle_value]
          end.to_h
        end
      end
    end
  end
end
