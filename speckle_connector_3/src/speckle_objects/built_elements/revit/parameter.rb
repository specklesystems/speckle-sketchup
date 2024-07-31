# frozen_string_literal: true

require_relative '../../base'
require_relative '../../../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      module Revit
        # Revit parameter.
        class Parameter < Base
          SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_PARAMETER
          def initialize(name:, application_id: nil)
            super(
              speckle_type: SPECKLE_TYPE,
              total_children_count: 0,
              application_id: application_id,
              id: id
            )
            self[:name] = name
          end
        end
      end
    end
  end
end
