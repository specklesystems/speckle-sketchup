# frozen_string_literal: true

require_relative '../../base'
require_relative '../../../constants/type_constants'

module SpeckleConnector
  module SpeckleObjects
    module BuiltElements
      module Revit
        # Family instance for Revit mappings.
        class FamilyInstance < Base
          SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_FAMILY_INSTANCE
          READER = SketchupModel::Reader
          QUERY = SketchupModel::Query
          DICTIONARY = SketchupModel::Dictionary

          # rubocop:disable Metrics/ParameterLists
          def initialize(family:, type:, level:, units:, base_point:, rotation:, application_id: nil)
            super(
              speckle_type: SPECKLE_TYPE,
              total_children_count: 0,
              application_id: application_id,
              id: nil
            )
            self[:family] = family
            self[:type] = type
            self[:level] = level
            self[:units] = units
            self[:basePoint] = base_point
            self[:rotation] = rotation
          end
          # rubocop:enable Metrics/ParameterLists
        end
      end
    end
  end
end
