require "sketchup"

# To Native conversions for the ConverterSketchup
module SpeckleSystems::SpeckleConnector::ToNative

  #Starting point for the conversion from speckle to native
  #Note: The following is a design decision to put the recieved objects into a root component. 
  #This allows for a cleaner import and allows for updates to an existing import. 
  def traverse_commit_object(base, stream_id)
    #find the stream definition if it already exists
    stream_name = "stream #{stream_id}"
    definitions = Sketchup.active_model.definitions
    definition = definitions[stream_name]

    #if the stream definition does exist, clear the definition
    if definition && definition.name == stream_name
      definition&.entities&.clear!
    else
      definition ||= definitions.add(stream_name)
    end

    #if their are no instances of the stream definition, add one to the scene at the origin point.
    if !definition.instances || definition.instances.count == 0
      entities = Sketchup.active_model.entities
      transformation = Geom::Transformation.new([0,0,0])
      componentinstance = entities.add_instance(definition, transformation)
    end

    #start the traversal of the speckle object graph to native sketchup
    traverse_commit_object_into_entities(base, definition.entities)
  end

  #Resursive method for the tranversal, validation, and conversion of speckle objects to native.
  #NOTE: this method requires an entities collection and does not assume the active_model.
  #This modification is necessary for better recursive traversal of the object graph. 
  #ie. groups within groups within groups... 
  def traverse_commit_object_into_entities(obj, entities)

    if can_convert_to_native(obj)
      convert_to_native(obj, entities)
    elsif obj.is_a?(Hash) && obj.key?("speckle_type")
      return if is_ignored_speckle_type(obj)

      #if the obj is a built element, create a group to put the geometry inside of.
      #ToDo: not sure if there is a case where an empty group would be created.
      if (obj.key?("speckle_type") && obj.key?("displayValue") && obj["speckle_type"].start_with?("Objects.BuiltElements"))
        element_group = entities.add_group
        element_name = obj["speckle_type"]
        element_name.gsub!("Objects.BuiltElements.", "")
        element_name = "#{element_name}_#{obj["elementId"]}"
        element_group.name = element_name
        entities = element_group.entities
        #puts(">>> Creating Element #{element_name}")
      end

      #traverse all the keys/properties of the obj
      props = obj.keys.filter_map { |key| key unless key.start_with?("_") }
      props.each { |prop| 

        #this is a little hacky but it checks if the object is defining a category. 
        #if so, it creates a group to house the elements. Organizing the scene graph like this
        #seems alot more clean and useful to the end-user.
        if prop.start_with?('@') && prop != "@displayValue"
          category_group = entities.add_group
          category_name = prop[1..-1]
          category_group.name = category_name
          #puts(">>> Creating Category: #{category_name}")
          traverse_commit_object_into_entities(obj[prop], category_group.entities) 
        else
          traverse_commit_object_into_entities(obj[prop], entities) 
        end
      }
    elsif obj.is_a?(Hash)
      obj.each_value { |value| traverse_commit_object_into_entities(value, entities) }
    elsif obj.is_a?(Array)
      obj.each { |value| traverse_commit_object_into_entities(value, entities) }
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
    when "Objects.Geometry.Brep" then mesh_to_native(obj["displayMesh"], entities)
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

  #NOTE: this is currently not used
  def face_to_native
    nil
  end

  def point_to_native(x, y, z, units)
    Geom::Point3d.new(length_to_native(x, units), length_to_native(y, units), length_to_native(z, units))
  end

  def point_to_native_array(x ,y ,z ,units)
    [length_to_native(x, units), length_to_native(y, units), length_to_native(z, units)]
  end

  # converts a mesh to a native mesh and adds the faces to the given entities collection
  def mesh_to_native(mesh, entities)
    _speckle_mesh_to_native_mesh(mesh, entities)
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

  #NOTE: this is currently not used.
  def _hidden_edges_mesh_to_native_mesh(mesh, entities)
    native_mesh = Geom::PolygonMesh.new(mesh["vertices"].count / 3)
    points = []
    mesh["vertices"].each_slice(3) do |pt|
      points.push(point_to_native(pt[0], pt[1], pt[2], mesh["units"]))
    end
    edge_flags = mesh["faceEdgeFlags"]
    faces = mesh["faces"]
    loops = []
    flags = []
    while faces.count.positive?
      num_pts = faces.shift
      # 0 -> 3, 1 -> 4 to preserve backwards compatibility
      num_pts += 3 if num_pts < 3
      indices = faces.shift(num_pts)
      current_edge_flags = edge_flags.shift(num_pts)
      outer_loop = indices.map { |index| points[index] }
      if current_edge_flags.include?(true)
        loops << outer_loop
        flags << current_edge_flags
      else
        native_mesh.add_polygon(outer_loop)
      end
    end
    entities.add_faces_from_mesh(native_mesh, 0, material_to_native(mesh["renderMaterial"]))

    loops.each do |l|
      loop_flags = flags.shift
      face = entities.add_face(l)
      face.edges.each_with_index { |edge, index| edge.soft = edge.smooth = loop_flags[index] }
    end

    native_mesh
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
    # puts("    entity count: #{definition.entities.count}")
    definition
  end

  # takes a component definition and finds and erases the first instance with the matching name (and optionally the applicationId)
  def find_and_erase_existing_instance(definition, name, app_id = "")
    definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
  end

  # creates a component instance from a block
  def component_instance_to_native(block, entities)
    # I know the previous version said this causes problems but I didn't have any problems using is_group.
    is_group = block.key?("is_sketchup_group") && block["is_sketchup_group"]
    name = block["name"].nil? || block["name"].empty? ? block["id"] : block["name"]
    transform = transform_to_native(
      block["transform"].is_a?(Hash) ? block["transform"]["value"] : block["transform"],
      block["units"]
    )

    block_def = block["blockDefinition"]

    if is_group
      instance = entities.add_group
      instance.transformation = transform
      instance.name = block_def["name"]
      block_def["geometry"].each { |obj| convert_to_native(obj, instance.entities) }
    else
      definition = component_definition_to_native(block_def["geometry"], block_def["name"], block_def["applicationId"])
      instance = entities.add_instance(definition, transform)
    end

    #puts("Failed to create instance for speckle block instance #{block["id"]}") if instance.nil?
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
