# frozen_string_literal: true

require_relative '../../base'
require_relative '../../built_elements/revit/parameter'
require_relative '../../other/render_material'
require_relative '../../geometry/line'
require_relative '../../geometry/length'
require_relative '../../../constants/type_constants'
require_relative '../../../sketchup_model/dictionary/speckle_schema_dictionary_handler'
require_relative '../../../sketchup_model/utils/face_utils'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Revit wall object.
      class RevitWall < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_WALL

        # rubocop:disable Metrics/ParameterLists
        def initialize(family:, type:, base_line:, height:, flipped:, level:, units:, material:, parameters: nil, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:family] = family
          self[:type] = type
          self[:height] = height
          self[:flipped] = flipped
          self[:level] = level
          self[:baseLine] = base_line
          self[:units] = units
          self[:parameters] = parameters
          self[:renderMaterial] = material
        end
        # rubocop:enable Metrics/ParameterLists

        def self.to_native(state, wall, layer, entities, &convert_to_native)
          obj = Other::DisplayValue.collect_definition_geometries(wall)
          obj['name'] = Other::DisplayValue.get_definition_name(obj)

          state, _definitions = Other::BlockDefinition.to_native(
            state, obj, layer, entities, &convert_to_native
          )

          definition = state.sketchup_state.sketchup_model.definitions[Other::BlockDefinition.get_definition_name(obj)]

          Other::BlockInstance.find_and_erase_existing_instance(definition, obj['id'], obj['applicationId'])
          t_arr = obj['transform']
          transform = t_arr.nil? ? Geom::Transformation.new : Other::Transform.to_native(t_arr, obj['units'])
          instance = entities.add_instance(definition, transform)
          instance.name = Other::DisplayValue.get_instance_name(obj['name']) unless obj['name'].nil?
          instance.layer = layer unless layer.nil?
          # Align instance axes that created from display value. (without any transform)
          # BlockInstance.align_instance_axes(instance)
          return state, [instance, definition]
        end

        # @param face [Sketchup::Face] face to get speckle schema for wall.
        def self.to_speckle_schema(speckle_state, face, units, global_transformation: nil)
          base_line = Geometry::Line.base_line_from_face(face, units, global_transformation: global_transformation)

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

          RevitWall.new(
            family: schema['family'],
            type: schema['family_type'],
            base_line: base_line,
            height: Geometry.length_to_speckle(SketchupModel::Utils::FaceUtils.max_z(face), units),
            flipped: false,
            level: level,
            units: units,
            parameters: parameters,
            material: material.nil? ? nil : Other::RenderMaterial.from_material(face.material || face.back_material),
            application_id: face.persistent_id
          )
        end

        def self.get_wall_height(face, units)
          points = face.vertices.collect(&:position)
          points_z_values = points.collect(&:z)
          Geometry.length_to_speckle(points_z_values.max - points_z_values.min, units)
        end
      end
    end
  end
end
