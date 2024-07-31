# frozen_string_literal: true

require_relative '../base'
require_relative '../built_elements/revit/parameter'
require_relative '../other/render_material'
require_relative '../geometry/length'
require_relative '../geometry/line'
require_relative '../geometry/polyline'
require_relative '../../constants/type_constants'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'
require_relative '../../sketchup_model/utils/face_utils'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Default Wall object.
      class DefaultWall < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_DEFAULT_WALL

        def initialize(base_line:, height:, flipped:, units:, material:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:baseLine] = base_line
          self[:height] = height
          self[:flipped] = flipped
          self[:units] = units
          self[:renderMaterial] = material
        end

        # @param face [Sketchup::Face] face to get speckle schema for floor.
        def self.to_speckle_schema(_speckle_state, face, units, global_transformation: nil)
          base_line = Geometry::Line.base_line_from_face(face, units, global_transformation: global_transformation)

          material = face.material || face.back_material

          DefaultWall.new(
            base_line: base_line,
            height: Geometry.length_to_speckle(SketchupModel::Utils::FaceUtils.max_z(face), units),
            flipped: false,
            units: units,
            material: material.nil? ? nil : Other::RenderMaterial.from_material(face.material || face.back_material),
            application_id: face.persistent_id
          )
        end
      end
    end
  end
end
