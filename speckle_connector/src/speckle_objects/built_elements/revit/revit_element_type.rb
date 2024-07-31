# frozen_string_literal: true

require_relative '../../base'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      module Revit
        # Revit element type.
        class RevitElementType < Base
          SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_REVITELEMENTTYPE

          # rubocop:disable Metrics/ParameterLists
          def initialize(category:, family:, type:, element_id:, application_id: nil, id: nil)
            super(
              speckle_type: SPECKLE_TYPE,
              total_children_count: 0,
              application_id: application_id,
              id: id
            )
            self[:category] = category
            self[:family] = family
            self[:type] = type
            self[:elementId] = element_id
          end
          # rubocop:enable Metrics/ParameterLists

          def self.to_native(revit_element_type)
            RevitElementType.new(
              category: revit_element_type['category'],
              family: revit_element_type['family'],
              type: revit_element_type['type'],
              element_id: revit_element_type['elementId'],
              application_id: revit_element_type['applicationId'],
              id: revit_element_type['id']
            )
          end
        end
      end
    end
  end
end
