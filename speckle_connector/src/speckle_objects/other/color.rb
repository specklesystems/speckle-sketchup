# frozen_string_literal: true

module SpeckleConnector
  module SpeckleObjects
    module Others
      # Color object transformations between sketchup and speckle.
      class Color
        # @param color [Sketchup::Color] color to convert speckle object
        def self.to_speckle(color)
          {
            red: color.red,
            green: color.green,
            blue: color.blue,
            alpha: color.alpha
          }
        end

        def self.to_native(speckle_color)
          Sketchup::Color.new(speckle_color['red'], speckle_color['green'],
                              speckle_color['blue'], speckle_color['alpha'])
        end
      end
    end
  end
end
