# frozen_string_literal: true

require_relative '../speckle_objects/geometry/length'

module SpeckleConnector
  COMBINE_FACES_BY_MATERIAL = :combine_faces_by_material
  INCLUDE_ENTITY_ATTRIBUTES = :include_entity_attributes
  INCLUDE_FACE_ENTITY_ATTRIBUTES = :include_face_entity_attributes
  INCLUDE_EDGE_ENTITY_ATTRIBUTES = :include_edge_entity_attributes
  INCLUDE_GROUP_ENTITY_ATTRIBUTES = :include_group_entity_attributes
  INCLUDE_COMPONENT_ENTITY_ATTRIBUTES = :include_component_entity_attributes
  MERGE_COPLANAR_FACES = :merge_coplanar_faces

  LEVEL_SHIFT_VALUE = SpeckleObjects::Geometry.length_to_native(1.5, 'm')

  DEFAULT_MODEL_PREFERENCES = {
    COMBINE_FACES_BY_MATERIAL => true,
    INCLUDE_ENTITY_ATTRIBUTES => true,
    INCLUDE_FACE_ENTITY_ATTRIBUTES => true,
    INCLUDE_EDGE_ENTITY_ATTRIBUTES => true,
    INCLUDE_GROUP_ENTITY_ATTRIBUTES => true,
    INCLUDE_COMPONENT_ENTITY_ATTRIBUTES => true,
    MERGE_COPLANAR_FACES => true
  }.freeze
end
