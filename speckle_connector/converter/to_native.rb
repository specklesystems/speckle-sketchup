require "sketchup"

# To Native conversions for the ConverterSketchup
module SpeckleSystems::SpeckleConnector::ToNative
  def length_to_native(length, units: @units)
    length.__send__(SpeckleSystems::SpeckleConnector::SKETCHUP_UNIT_STRINGS[units])
  end

  def edge_to_native(line)
    return unless line.key?("value")

    values = line["value"]
    points =
      values.each_slice(3).to_a.map do |pt|
        Geom::Point3d.new(
          length_to_native(pt[0], line["units"]),
          length_to_native(pt[1], line["units"]),
          length_to_native(pt[2], line["units"])
        )
      end
    Sketchup.active_model.active_entities.add_edges(*points)
  end

  def face_to_native
    nil
  end

  def point_to_native(point)
    Geom::Point3d.new(
      length_to_native(point["x"], point["units"]),
      length_to_native(point["y"], point["units"]),
      length_to_native(point["z"], point["units"])
    )
  end

  def component_definition_to_native
    nil
  end

  def component_instance_to_native
    nil
  end

  def transform_to_native(t_arr, units: @units)
    Geom::Transformation.new(
      [
      t_arr[0], t_arr[4], t_arr[8],  t_arr[12],
      t_arr[1], t_arr[5], t_arr[9],  t_arr[13],
      t_arr[2], t_arr[6], t_arr[10], t_arr[14],
      length_to_native(t_arr[3], units),
      length_to_native(t_arr[7], units),
      length_to_native(t_arr[11], units),
      t_arr[15]
      ]
    )
  end

  def material_to_native(render_mat)
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
