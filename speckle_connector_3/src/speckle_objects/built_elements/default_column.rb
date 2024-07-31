# frozen_string_literal: true

require_relative '../base'
require_relative '../geometry/line'
require_relative '../../constants/type_constants'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Default Column object.
      class DefaultColumn < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_DEFAULT_COLUMN

        def initialize(base_line:, units:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:baseLine] = base_line
          self[:units] = units
        end

        # @param edge [Sketchup::Edge] edge to get speckle schema for column.
        def self.to_speckle_schema(_speckle_state, edge, units, global_transformation: nil)
          base_line = Geometry::Line.to_speckle_schema(edge: edge, units: units)

          DefaultColumn.new(
            base_line: base_line,
            units: units,
            application_id: edge.persistent_id
          )
        end
      end
    end
  end
end
