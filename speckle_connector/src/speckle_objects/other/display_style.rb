# frozen_string_literal: true

require_relative 'color'
require_relative '../base'
require_relative '../../constants/type_constants'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # DisplayStyle object for layer.
      class DisplayStyle < Base
        def initialize(name:, color:, line_type:)
          super(
            speckle_type: OBJECTS_OTHER_DISPLAYSTYLE,
            total_children_count: 0,
            application_id: nil,
            id: nil
          )
          self[:name] = name
          self[:color] = color
          self[:linetype] = line_type unless line_type.nil?
        end

        # @param layer [Sketchup::Layer] layer to get display style.
        def self.from_layer(layer)
          DisplayStyle.new(
            name: '',
            color: Color.to_int(layer.color),
            line_type: layer.line_style.nil? ? nil : layer.line_style.name
          )
        end
      end
    end
  end
end
