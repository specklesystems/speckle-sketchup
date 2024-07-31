# frozen_string_literal: true

require_relative '../../base'
require_relative '../../built_elements/revit/parameter'
require_relative '../../geometry/line'
require_relative '../../../constants/type_constants'
require_relative '../../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Revit column object.
      class RevitColumn < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_COLUMN

        # rubocop:disable Metrics/ParameterLists
        def initialize(family:, type:, base_line:, level:, units:, parameters:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:family] = family
          self[:type] = type
          self[:level] = level
          self[:baseLine] = base_line
          self[:units] = units
          self[:parameters] = parameters
        end
        # rubocop:enable Metrics/ParameterLists

        # @param edge [Sketchup::Edge] edge to get speckle schema for column.
        def self.to_speckle_schema(speckle_state, edge, units, global_transformation: nil)
          base_line = Geometry::Line.to_speckle_schema(edge: edge, units: units)
          schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.speckle_schema_to_speckle(edge).to_h
          source_exist = !speckle_state.speckle_mapper_state.mapper_source.nil?
          level = nil
          if source_exist
            level = speckle_state.speckle_mapper_state.mapper_source.levels.find { |l| l[:name] == schema['level'] }
            parameters = Base.new
            offset_parameter = BuiltElements::Revit::Parameter.new(name: 'Height Offset From Level')
            level_z = Geometry.length_to_native(level[:elevation], level[:units])
            min_z = [edge.start.position, edge.end.position].map(&:z).min
            offset_parameter['value'] = Geometry.length_to_speckle(min_z - level_z, units)
            offset_parameter['units'] = units
            parameters['Height Offset From Level'] = offset_parameter
          end

          RevitColumn.new(
            family: schema['family'],
            type: schema['family_type'],
            base_line: base_line,
            level: level,
            units: units,
            parameters: parameters,
            application_id: edge.persistent_id
          )
        end
      end
    end
  end
end
