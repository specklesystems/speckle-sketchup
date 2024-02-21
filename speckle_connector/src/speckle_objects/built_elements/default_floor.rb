# frozen_string_literal: true

require_relative '../base'
require_relative '../built_elements/revit/parameter'
require_relative '../other/render_material'
require_relative '../geometry/line'
require_relative '../geometry/polyline'
require_relative '../../constants/type_constants'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module BuiltElements
      # Default Floor object.
      class DefaultFloor < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_DEFAULT_FLOOR

        def initialize(outline:, voids:, units:, material:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:outline] = outline
          self[:voids] = voids
          self[:units] = units
          self[:renderMaterial] = material
        end

        # @param face [Sketchup::Face] face to get speckle schema for floor.
        def self.to_speckle_schema(_speckle_state, face, units, global_transformation: nil)
          outline = Geometry::Polyline.from_loop(face.loops.first, units, global_transformation: global_transformation)
          voids = []
          if face.loops.length > 1
            voids = face.loops[1..face.loops.length - 1].collect do |loop|
              Geometry::Polyline.from_loop(loop, units, global_transformation: global_transformation)
            end
          end
          material = face.material || face.back_material

          DefaultFloor.new(
            outline: outline,
            voids: voids,
            units: units,
            material: material.nil? ? nil : Other::RenderMaterial.from_material(face.material || face.back_material),
            application_id: face.persistent_id
          )
        end
      end
    end
  end
end
