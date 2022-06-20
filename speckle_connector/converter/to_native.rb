require "sketchup"

# To Native conversions for the ConverterSketchup
module SpeckleSystems::SpeckleConnector::ToNative
  def traverse_commit_object(obj)
    if can_convert_to_native(obj)
      convert_to_native(obj, Sketchup.active_model.entities)
    elsif obj.is_a?(Hash) && obj.key?("speckle_type")
      return if is_ignored_speckle_type(obj)

      if obj["displayValue"].nil?
        puts(">>> Found #{obj["speckle_type"]}: #{obj["id"]}. Continuing traversal.")
        props = obj.keys.filter_map { |key| key unless key.start_with?("_") }
        props.each { |prop| traverse_commit_object(obj[prop]) }
      else
        puts(">>> Found #{obj["speckle_type"]}: #{obj["id"]} with displayValue.")
        convert_to_native(obj)
      end
    elsif obj.is_a?(Hash)
      obj.each_value { |value| traverse_commit_object(value) }
    elsif obj.is_a?(Array)
      obj.each { |value| traverse_commit_object(value) }
    else
      nil
    end
  end

  def can_convert_to_native(obj)
    return false unless obj.is_a?(Hash) && obj.key?("speckle_type")

    [
      "Objects.Geometry.Line",
      "Objects.Geometry.Polyline",
      "Objects.Geometry.Mesh",
      "Objects.Geometry.Brep",
      "Objects.Other.BlockInstance",
      "Objects.Other.BlockDefinition",
      "Objects.Other.RenderMaterial"
    ].include?(obj["speckle_type"])
  end

  def is_ignored_speckle_type(obj)
    ["Objects.BuiltElements.Revit.Parameter"].include?(obj["speckle_type"])
  end

  def convert_to_native(obj, entities = Sketchup.active_model.entities)
    return display_value_to_native_component(obj, entities) unless obj["displayValue"].nil?

    case obj["speckle_type"]
    when "Objects.Geometry.Line", "Objects.Geometry.Polyline" then edge_to_native(obj, entities)
    when "Objects.Other.BlockInstance" then component_instance_to_native(obj, entities)
    when "Objects.Other.BlockDefinition" then component_definition_to_native(obj)
    when "Objects.Geometry.Mesh" then mesh_to_native(obj, entities)
    when "Objects.Geometry.Brep" then mesh_to_native(obj["displayValue"], entities)
    else
      nil
    end
    rescue StandardError => e
      puts("Failed to convert #{obj["speckle_type"]} (id: #{obj["id"]})")
      puts(e)
      nil
  end

  def length_to_native(length, units = @units)
    length.__send__(SpeckleSystems::SpeckleConnector::SKETCHUP_UNIT_STRINGS[units])
  end

  def edge_to_native(line, entities)
    if line.key?("value")
      values = line["value"]
      points = values.each_slice(3).to_a.map { |pt| point_to_native(pt[0], pt[1], pt[2], line["units"]) }
      points.push(points[0]) if line["closed"]
      entities.add_edges(*points)
    else
      start_pt = point_to_native(line["start"]["x"], line["start"]["y"], line["start"]["z"], line["units"])
      end_pt = point_to_native(line["end"]["x"], line["end"]["y"], line["end"]["z"], line["units"])
      entities.add_edges(start_pt, end_pt)
    end
  end

  def edge_to_native_component(line, entities)
    line_id = line["applicationId"].to_s.empty? ? line["id"] : line["applicationId"]
    definition = component_definition_to_native([line], "def::#{line_id}")
    find_and_erase_existing_instance(definition, line_id)
    instance = entities.add_instance(definition, Geom::Transformation.new)
    instance.name = line_id
    instance
  end

  def face_to_native
    nil
  end

  def point_to_native(x, y, z, units)
    Geom::Point3d.new(length_to_native(x, units), length_to_native(y, units), length_to_native(z, units))
  end

  # converts a mesh to a native mesh and adds the faces to the given entities collection
  def mesh_to_native(mesh, entities)
    if mesh["facesWithEdges"].nil?
      _speckle_mesh_to_native_mesh(mesh, entities)
    else
      _hidden_edges_mesh_to_native_mesh(mesh, entities)
    end
  end

  def _speckle_mesh_to_native_mesh(mesh, entities)
    native_mesh = Geom::PolygonMesh.new(mesh["vertices"].count / 3)
    points = []
    mesh["vertices"].each_slice(3) do |pt|
      points.push(point_to_native(pt[0], pt[1], pt[2], mesh["units"]))
    end
    faces = mesh["faces"]
    while faces.count.positive?
      num_pts = faces.shift
      # 0 -> 3, 1 -> 4 to preserve backwards compatibility
      num_pts += 3 if num_pts < 3
      indices = faces.shift(num_pts)
      native_mesh.add_polygon(indices.map { |index| points[index] })
    end
    entities.add_faces_from_mesh(native_mesh, 4, material_to_native(mesh["renderMaterial"]))

    native_mesh
  end

  def _hidden_edges_mesh_to_native_mesh(mesh, entities)
    native_mesh = Geom::PolygonMesh.new(mesh["vertices"].count / 3)
    points = []
    mesh["vertices"].each_slice(3) do |pt|
      points.push(point_to_native(pt[0], pt[1], pt[2], mesh["units"]))
    end
    faces = mesh["facesWithEdges"]
    while faces.count.positive?
      num_pts = faces.shift
      # 0 -> 3, 1 -> 4 to preserve backwards compatibility
      num_pts += 3 if num_pts < 3
      indices = faces.shift(num_pts)
      edge_indices = indices.map(&:abs) << indices[0].abs
      edge_points = edge_indices.map { |index| points[index - 1] }
      edges = entities.add_edges(edge_points)
      edges.each_with_index { |edge, index| edge.soft = edge.smooth = indices[index].negative? }
      native_mesh.add_polygon(edge_points[0..-2])
    end

    entities.add_faces_from_mesh(native_mesh, 0, material_to_native(mesh["renderMaterial"]))
  end

  # creates a component definition and instance from a speckle object with a display value
  def display_value_to_native_component(obj, entities)
    obj_id = obj["applicationId"].to_s.empty? ? obj["id"] : obj["applicationId"]
    definition = component_definition_to_native(obj["displayValue"], "def::#{obj_id}")
    find_and_erase_existing_instance(definition, obj_id)
    transform = obj["transform"].nil? ? Geom::Transformation.new : transform_to_native(obj["transform"])
    instance = entities.add_instance(definition, transform)
    instance.name = obj_id
    instance
  end

  # finds or creates a component definition from the geometry and the given name
  def component_definition_to_native(geometry, name, application_id = "")
    definition = Sketchup.active_model.definitions[name]
    return definition if definition && (definition.name == name || definition.guid == application_id)

    definition&.entities&.clear!
    definition ||= Sketchup.active_model.definitions.add(name)
    geometry.each { |obj| convert_to_native(obj, definition.entities) }
    puts("definition finished: #{name} (#{application_id})")
    puts("    entity count: #{definition.entities.count}")
    definition
  end

  # takes a component definition and finds and erases the first instance with the matching name (and optionally the applicationId)
  def find_and_erase_existing_instance(definition, name, app_id = "")
    definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
  end

  # creates a component instance from a block
  def component_instance_to_native(block, entities)
    # is_group = block.key?("is_sketchup_group") && block["is_sketchup_group"]
    # something about this conversion is freaking out if nested block geo is a group
    # so this is set to false always until I can figure this out
    is_group = false

    definition = component_definition_to_native(
      block["blockDefinition"]["geometry"],
      block["blockDefinition"]["name"],
      block["blockDefinition"]["applicationId"]
    )
    name = block["name"].nil? || block["name"].empty? ? block["id"] : block["name"]
    transform = transform_to_native(
      block["transform"].is_a?(Hash) ? block["transform"]["value"] : block["transform"],
      block["units"]
    )
    instance =
    if is_group
      entities.add_group(definition.entities.to_a)
    else
      entities.add_instance(definition, transform)
    end
    # erase existing instances after creation and before rename because you can't have definitions without instances
    find_and_erase_existing_instance(definition, name, block["applicationId"])
    puts("Failed to create instance for speckle block instance #{block["id"]}") if instance.nil?
    instance.transformation = transform if is_group
    instance.material = material_to_native(block["renderMaterial"])
    instance.name = name
    instance
  end

  def transform_to_native(t_arr, units = @units)
    Geom::Transformation.new(
      [
        t_arr[0],
        t_arr[4],
        t_arr[8],
        t_arr[12],
        t_arr[1],
        t_arr[5],
        t_arr[9],
        t_arr[13],
        t_arr[2],
        t_arr[6],
        t_arr[10],
        t_arr[14],
        length_to_native(t_arr[3], units),
        length_to_native(t_arr[7], units),
        length_to_native(t_arr[11], units),
        t_arr[15]
      ]
    )
  end

  def material_to_native(render_mat)
    return if render_mat.nil?

    # return material with same name if it exists
    name = render_mat["name"] || render_mat["id"]
    material = Sketchup.active_model.materials[name]
    return material if material

    # create a new sketchup material
    material = Sketchup.active_model.materials.add(name)
    material.alpha = render_mat["opacity"]
    argb = render_mat["diffuse"]
    material.color = Sketchup::Color.new((argb >> 16) & 255, (argb >> 8) & 255, argb & 255, (argb >> 24) & 255)
    material
  end
end
