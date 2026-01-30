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

module SpeckleConnector3
  module SpeckleObjects
    # Geometry objects in the Speckleverse.
    module Geometry
      # Mesh object that grouped with different faces.
      # This is a destructive process but for performance reasons.
      class GroupedMesh
        # @return [Array<Sketchup::Face>] faces that grouped under same layer and material
        attr_reader :faces

        # @return [Sketchup::Layer] layer that faces belong to
        attr_reader :layer

        # @return [Sketchup::Material] material that faces belong to
        attr_reader :material

        # @return [String] fake id for grouped mesh
        attr_reader :persistent_id

        # @return [String] fake id for grouped mesh
        attr_reader :entityID

        # @return Hash{String=>Sketchup::Face}
        attr_reader :mesh_groups

        def initialize(faces, layer, material)
          @faces = faces
          @persistent_id = faces.first.persistent_id.to_s
          @entityID = faces.first.persistent_id.to_s
          @layer = layer
          @material = material
          @mesh_groups = {}
        end
      end
    end
  end
end
