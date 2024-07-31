# frozen_string_literal: true

require_relative '../../base'
require_relative '../../built_elements/revit/parameter'
require_relative '../../other/render_material'
require_relative '../../geometry/line'
require_relative '../../geometry/polyline'
require_relative '../../../constants/type_constants'
require_relative '../../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Revit floor object.
      class RevitFloor < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_FLOOR

        # rubocop:disable Metrics/ParameterLists
        def initialize(family:, type:, outline:, voids:, level:, units:, material:, parameters:nil, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:family] = family
          self[:type] = type
          self[:level] = level
          self[:outline] = outline
          self[:voids] = voids
          self[:units] = units
          self[:parameters] = parameters
          self[:renderMaterial] = material
        end
        # rubocop:enable Metrics/ParameterLists

        # @param face [Sketchup::Face] face to get speckle schema for floor.
        def self.to_speckle_schema(speckle_state, face, units, global_transformation: nil)
          outline = Geometry::Polyline.from_loop(face.loops.first, units, global_transformation: global_transformation)
          voids = []
          if face.loops.length > 1
            voids = face.loops[1..face.loops.length - 1].collect do |loop|
              Geometry::Polyline.from_loop(loop, units, global_transformation: global_transformation)
            end
          end
          material = face.material || face.back_material
          schema = SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.speckle_schema_to_speckle(face).to_h
          source_exist = !speckle_state.speckle_mapper_state.mapper_source.nil?
          level = nil
          parameters = nil
          if source_exist
            level = speckle_state.speckle_mapper_state.mapper_source.levels.find { |l| l[:name] == schema['level'] }
            parameters = Base.new
            offset_parameter = BuiltElements::Revit::Parameter.new(name: 'Height Offset From Level')
            level_z = Geometry.length_to_native(level[:elevation], level[:units])
            min_z = face.vertices.collect(&:position).map(&:z).min
            offset_parameter['value'] = Geometry.length_to_speckle(min_z - level_z, units)
            offset_parameter['units'] = units
            parameters['Height Offset From Level'] = offset_parameter
          end

          RevitFloor.new(
            family: schema['family'],
            type: schema['family_type'],
            outline: outline,
            voids: voids,
            level: level,
            units: units,
            parameters: parameters,
            material: material.nil? ? nil : Other::RenderMaterial.from_material(face.material || face.back_material),
            application_id: face.persistent_id
          )
        end
      end
    end
  end
end
