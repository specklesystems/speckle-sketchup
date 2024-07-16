# frozen_string_literal: true

require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../other/render_material'
require_relative '../../mapper/mapper'
require_relative '../../sketchup_model/query/entity'
require_relative '../../convertors/clean_up'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'
require_relative '../../sketchup_model/dictionary/speckle_schema_dictionary_handler'
require_relative '../../sketchup_model/dictionary/dictionary_handler'
require_relative '../../sketchup_model/utils/plane_utils'
require_relative '../../sketchup_model/query/layer'

module SpeckleConnector
  module SpeckleObjects
    # Geometry objects in the Speckleverse.
    module Geometry
      # Mesh object that grouped with different faces.
      # This is a destructive process but for performance reasons.
      class GroupedMesh
        attr_reader :faces

        attr_reader :layer

        attr_reader :material

        attr_reader :persistent_id

        # @return Hash{String=>Sketchup::Face}
        attr_reader :mesh_groups

        def initialize(faces, layer, material, persistent_id)
          @faces = faces
          @persistent_id = persistent_id
          @layer = layer
          @material = material
          @mesh_groups = {}
        end

        # @param
        def self.to_speckle(faces, speckle_state, preferences, parent, &convert)
          mesh_groups = {}
          faces.collect do |face|
            # FIXME: GROUPED MESHES
            next unless SketchupModel::Dictionary::SpeckleSchemaDictionaryHandler.attribute_dictionary(face).nil?

            new_speckle_state = group_meshes_by_material(
              face, mesh_groups, speckle_state, preferences, parent, &convert
            )
            speckle_state = new_speckle_state
          end
          mesh_groups.each { |_, mesh| mesh.update_mesh unless mesh.is_a?(SpeckleObjects::ObjectReference) }
          return speckle_state, mesh_groups.values
        end

        def self.group_meshes_by_material(face, mesh_groups, speckle_state, preferences, parent, &convert)
          # convert material
          mesh_group_id = SpeckleObjects::Geometry::Mesh.get_mesh_group_id(face, preferences[:model])
          new_speckle_state, converted = convert.call(face, preferences, speckle_state, parent, true)
          mesh_groups[mesh_group_id] = converted unless mesh_groups.key?(mesh_group_id)
          mesh_group = mesh_groups[mesh_group_id]
          mesh_group.face_to_mesh(face)
          new_speckle_state
        end
      end
    end
  end
end
