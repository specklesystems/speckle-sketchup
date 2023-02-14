# frozen_string_literal: true

module SpeckleConnector
  MAT_DICTIONARY = 'Speckle_Connector_Materials'
  MAT_ID = 'Speckle_Connector_Material_Id'

  MAT_ADD = :speckle_connector_add_material
  MAT_EDIT = :speckle_connector_edit_material
  MAT_REMOVE = :speckle_connector_remove_material

  DEFAULT_COLORS = {
    MAT_ADD => '#66FF66',
    MAT_EDIT => '#FFFF9F',
    MAT_REMOVE => '#FF6666'
  }.freeze

  DEFAULT_NAMES = {
    MAT_ADD => 'Speckle_Material_Add',
    MAT_EDIT => 'Speckle_Material_Edit',
    MAT_REMOVE => 'Speckle_Material_Remove'
  }.freeze
end
