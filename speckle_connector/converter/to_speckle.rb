require "sketchup"

# To Speckle conversions for the ConverterSketchup
module SpeckleSystems::SpeckleConnector::ToSpeckle
  def length_to_speckle(length)
    length.__send__("to_#{SpeckleSystems::SpeckleConnector::SKETCHUP_UNIT_STRINGS[@units]}")
  end

  def edge_to_speckle(edge)
    {
      speckle_type: "Objects.Geometry.Line",
      applicationId: edge.persistent_id.to_s,
      units: @units,
      start: vertex_to_speckle(edge.start),
      end: vertex_to_speckle(edge.end),
      domain: speckle_interval(0, Float(edge.length)),
      bbox: bounds_to_speckle(edge.bounds)
    }
  end

  def component_definition_to_speckle(definition)
    guid = definition.guid
    return @component_defs[guid] if @component_defs.key?(guid)

    speckle_def = {
      speckle_type: "Objects.Other.BlockDefinition",
      applicationId: guid,
      units: @units,
      name: definition.name,
      # i think the base point is always the origin?
      basePoint: speckle_point,
      "@geometry" => if %w[Edge Face].include?(definition.entities[0].typename)
                       group_mesh_to_speckle(definition)
                     else
                       definition.entities.map { |entity| convert_to_speckle(entity) }
                     end
    }
    @component_defs[guid] = speckle_def
  end

  def component_instance_to_speckle(instance, is_group: false)
    transform = instance.transformation
    origin = transform.origin
    {
      speckle_type: "Objects.Other.BlockInstance",
      applicationId: instance.guid,
      is_sketchup_group: is_group,
      units: @units,
      bbox: bounds_to_speckle(instance.bounds),
      name: instance.name,
      renderMaterial: instance.material.nil? ? nil : material_to_speckle(instance.material),
      transform: transform_to_speckle(transform),
      insertionPoint: speckle_point(origin[0], origin[1], origin[2]),
      "@blockDefinition" => component_definition_to_speckle(instance.definition)
    }
  end

  def group_mesh_to_speckle(component_def)
    mat_groups = {}

    component_def.entities.each do |face|
      next unless face.typename == "Face"

      # convert material
      mat_id = face.material.nil? ? "none" : face.material.entityID
      mat_groups[mat_id] = initialise_group_mesh(face, component_def.bounds) unless mat_groups.key?(mat_id)

      # add points and texture coordinates
      mesh = face.mesh(1)
      mat_groups[mat_id]["@(31250)vertices"].push(*points_to_array(mesh))
      mat_groups[mat_id]["@(31250)textureCoordinates"].push(*uvs_to_array(mesh))

      # add faces
      mat_groups[mat_id]["@(62500)faces"].push(*faces_to_array(mesh, mat_groups[mat_id][:pt_count]))
      mat_groups[mat_id][:pt_count] += mesh.points.count
    end

    mat_groups.values.map { |group| group.delete(:pt_count) }
    mat_groups.values
  end

  def transform_to_speckle(transform)
    t_arr = transform.to_a
    [
      t_arr[0], t_arr[4], t_arr[8],  length_to_speckle(t_arr[12]),
      t_arr[1], t_arr[5], t_arr[9],  length_to_speckle(t_arr[13]),
      t_arr[2], t_arr[6], t_arr[10], length_to_speckle(t_arr[14]),
      t_arr[3], t_arr[7], t_arr[11], t_arr[15]
    ]
  end

  def initialise_group_mesh(face, bounds)
    {
      speckle_type: "Objects.Geometry.Mesh",
      units: @units,
      bbox: bounds_to_speckle(bounds),
      "@(31250)vertices" => [],
      "@(62500)faces" => [],
      "@(31250)textureCoordinates" => [],
      pt_count: -1, # faces are 1 indexed
      renderMaterial: face.material.nil? ? nil : material_to_speckle(face.material)
    }
  end

  def faces_to_array(mesh, offset)
    faces = []
    mesh.polygons.each do |poly|
      faces.push(
        case poly.count
        when 3 then 0   # tris
        when 4 then 1   # polys
        else
          poly.count # ngons
        end,
        *poly.map { |coord| coord.abs + offset }
      )
    end
    faces
  end

  def points_to_array(mesh)
    pts_array = []
    mesh.points.each do |pt|
      pts_array.push(
        length_to_speckle(pt[0]),
        length_to_speckle(pt[1]),
        length_to_speckle(pt[2])
      )
    end
    pts_array
  end

  def uvs_to_array(mesh)
    uvs_array = []
    mesh.uvs(true).each do |pt|
      uvs_array.push(
        length_to_speckle(pt[0] / pt[2]),
        length_to_speckle(pt[1] / pt[2])
      )
    end
    uvs_array
  end

  def face_to_speckle(face)
    mesh = face.mesh(1)
    {
      speckle_type: "Objects.Geometry.Mesh",
      units: @units,
      renderMaterial: face.material.nil? ? nil : material_to_speckle(face.material),
      bbox: bounds_to_speckle(face.bounds),
      "@(31250)vertices" => points_to_array(mesh),
      "@(62500)faces" => faces_to_array(mesh, -1),
      "@(31250)textureCoordinates" => uvs_to_array(mesh)
    }
  end

  def vertex_to_speckle(vertex)
    point = vertex.position
    {
      speckle_type: "Objects.Geometry.Point",
      units: @units,
      x: length_to_speckle(point[0]),
      y: length_to_speckle(point[1]),
      z: length_to_speckle(point[2])
    }
  end

  def material_to_speckle(material)
    rgba = material.color.to_a
    {
      speckle_type: "Objects.Other.RenderMaterial",
      name: material.name,
      diffuse: [rgba[3] << 24 | rgba[0] << 16 | rgba[1] << 8 | rgba[2]].pack("l").unpack1("l"),
      opacity: material.alpha,
      emissive: -16_777_216,
      metalness: 0,
      roughness: 1
    }
  end

  def bounds_to_speckle(bounds)
    min_pt = bounds.min
    {
      speckle_type: "Objects.Geometry.Box",
      units: @units,
      area: 0,
      volume: 0,
      xSize: speckle_interval(min_pt[0], bounds.width),
      ySize: speckle_interval(min_pt[1], bounds.height),
      zSize: speckle_interval(min_pt[2], bounds.depth),
      basePlane: speckle_plane
    }
  end

  def speckle_interval(start_val, end_val)
    {
      speckle_type: "Objects.Primitive.Interval",
      units: @units,
      start: start_val.is_a?(Length) ? length_to_speckle(start_val) : start_val,
      end: end_val.is_a?(Length) ? length_to_speckle(end_val) : end_val
    }
  end

  def speckle_point(x = 0.0, y = 0.0, z = 0.0, vector: false)
    {
      speckle_type: vector ? "Objects.Geometry.Vector" : "Objects.Geometry.Point",
      units: @units,
      x: x.is_a?(Length) ? length_to_speckle(x) : x,
      y: y.is_a?(Length) ? length_to_speckle(y) : y,
      z: z.is_a?(Length) ? length_to_speckle(z) : z
    }
  end

  def speckle_vector(x = 0.0, y = 0.0, z = 0.0)
    speckle_point(x, y, z, vector: true)
  end

  def speckle_plane(xdir: [1, 0, 0], ydir: [0, 1, 0], normal: [0, 0, 1], origin: [0, 0, 0])
    {
      speckle_type: "Objects.Geometry.Plane",
      units: @units,
      xdir: speckle_vector(*xdir),
      ydir: speckle_vector(*ydir),
      normal: speckle_vector(*normal),
      origin: speckle_point(*origin)
    }
  end
end
