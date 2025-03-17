# frozen_string_literal: true

module SpeckleConnector3
  module SpeckleObjects
    # @return [Array] available speckle object types.
    AVAILABLE_SPECKLE_OBJECTS = %w[
      Objects.Geometry.Point
      Objects.Geometry.Vector
      Objects.Geometry.Line
      Objects.Geometry.Polyline
      Objects.Geometry.Mesh
      Objects.Geometry.Brep
      Objects.Geometry.Box
      Objects.Geometry.Plane
      Objects.Other.BlockInstance
      Objects.Other.BlockDefinition
      Objects.Other.RenderMaterial
      Objects.Other.Transform
      Objects.Primitive.Interval
      Speckle.Reference
    ].freeze
  end
end
