# frozen_string_literal: true

module SpeckleConnector
  module SpeckleObjects
    module Other
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
          return from_int(speckle_color) if speckle_color.is_a?(Numeric)

          Sketchup::Color.new(speckle_color['red'], speckle_color['green'],
                              speckle_color['blue'], speckle_color['alpha'])
        end

        # @param color [Sketchup::Color] color to convert speckle object
        # @return [Numeric] int value of the color
        def self.to_int(color)
          rgba = color.to_a
          [rgba[3] << 24 | rgba[0] << 16 | rgba[1] << 8 | rgba[2]].pack('l').unpack1('l').to_i
        end

        # @param color [Sketchup::Color] color to convert speckle object
        def self.to_hex(color)
          r, g, b, a = color.to_a
          "#%02X%02X%02X" % [r, g, b] # Scale alpha value to 0-255 range
        end

        # @param argb [Numeric] int value of the corresponding color
        # @return [Sketchup::Color] sketchup color
        def self.from_int(argb)
          Sketchup::Color.new((argb >> 16) & 255, (argb >> 8) & 255, argb & 255, (argb >> 24) & 255)
        end
      end
    end
  end
end
