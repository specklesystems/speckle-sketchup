# frozen_string_literal: true

require_relative '../base'
require_relative '../other/render_material'
require_relative '../geometry/line'
require_relative '../geometry/polyline'
require_relative '../../constants/type_constants'

module SpeckleConnector
  module SpeckleObjects
    module BuiltElements
      # Level object.
      class Level < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_LEVEL

        # @param state [States::State] state of the application.
        def self.to_native(state, speckle_level, layer, entities, &_convert_to_native)

        end
      end
    end
  end
end
