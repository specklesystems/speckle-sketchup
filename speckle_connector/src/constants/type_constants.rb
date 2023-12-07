# frozen_string_literal: true

module SpeckleConnector
  BASE_OBJECT = 'Base'

  OBJECTS_GIS_POLYGONELEMENT = 'Objects.GIS.PolygonElement'
  OBJECTS_GIS_LINEELEMENT = 'Objects.GIS.LineElement'

  OBJECTS_BUILTELEMENTS_VIEW3D = 'Objects.BuiltElements.View:Objects.BuiltElements.View3D'
  OBJECTS_BUILTELEMENTS_NETWORK = 'Objects.BuiltElements.Network'
  OBJECTS_BUILTELEMENTS_REVIT_LEVEL = 'Objects.BuiltElements.Level:Objects.BuiltElements.Revit.RevitLevel'
  OBJECTS_BUILTELEMENTS_DEFAULT_FLOOR = 'Objects.BuiltElements.Floor'
  OBJECTS_BUILTELEMENTS_REVIT_FLOOR = 'Objects.BuiltElements.Floor:Objects.BuiltElements.Revit.RevitFloor'
  OBJECTS_BUILTELEMENTS_DEFAULT_WALL = 'Objects.BuiltElements.Wall'
  OBJECTS_BUILTELEMENTS_REVIT_WALL = 'Objects.BuiltElements.Wall:Objects.BuiltElements.Revit.RevitWall'
  OBJECTS_BUILTELEMENTS_REVIT_DIRECTSHAPE = 'Objects.BuiltElements.Revit.DirectShape'
  OBJECTS_BUILTELEMENTS_REVIT_FAMILY_INSTANCE = 'Objects.BuiltElements.Revit.FamilyInstance'
  OBJECTS_BUILTELEMENTS_REVIT_PARAMETER = 'Objects.BuiltElements.Revit.Parameter'
  OBJECTS_BUILTELEMENTS_REVIT_REVITELEMENTTYPE = 'Objects.BuiltElements.Revit.RevitElementType'
  OBJECTS_BUILTELEMENTS_REVIT_REVITSYMBOLELEMENTTYPE = 'Objects.BuiltElements.Revit.RevitElementType:Objects.BuiltElements.Revit.RevitSymbolElementType'

  OBJECTS_GEOMETRY_LINE = 'Objects.Geometry.Line'
  OBJECTS_GEOMETRY_POLYLINE = 'Objects.Geometry.Polyline'
  OBJECTS_GEOMETRY_POLYCURVE = 'Objects.Geometry.Polycurve'
  OBJECTS_GEOMETRY_ARC = 'Objects.Geometry.Arc'
  OBJECTS_GEOMETRY_CIRCLE = 'Objects.Geometry.Circle'
  OBJECTS_GEOMETRY_MESH = 'Objects.Geometry.Mesh'
  OBJECTS_GEOMETRY_BREP = 'Objects.Geometry.Brep'

  OBJECTS_OTHER_BLOCKINSTANCE = 'Objects.Other.BlockInstance'
  OBJECTS_OTHER_BLOCKINSTANCE_FULL = 'Objects.Other.Instance:Objects.Other.BlockInstance'
  OBJECTS_OTHER_INSTANCE = 'Objects.Other.Instance:Objects.Other.Instance'
  OBJECTS_OTHER_REVIT_REVITINSTANCE = 'Objects.Other.Revit.RevitInstance'
  OBJECTS_OTHER_BLOCKDEFINITION = 'Objects.Other.BlockDefinition'
  OBJECTS_OTHER_RENDERMATERIAL = 'Objects.Other.RenderMaterial'
  OBJECTS_OTHER_DISPLAYSTYLE = 'Objects.Other.DisplayStyle'

  SPECKLE_CORE_MODELS_COLLECTION = 'Speckle.Core.Models.Collection'
  SPECKLE_CORE_MODELS_COLLECTION_RASTER_LAYER = 'Speckle.Core.Models.Collection:Objects.GIS.RasterLayer'
  SPECKLE_CORE_MODELS_COLLECTION_VECTOR_LAYER = 'Speckle.Core.Models.Collection:Objects.GIS.VectorLayer'
end
