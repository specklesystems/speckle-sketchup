require "sketchup"

# To Native conversions for the ConverterSketchup
module SpeckleSystems::SpeckleConnector::ToNative
  def edge_to_native(line)
    return unless line.key?("value")

    values = line["value"]
    points =
      values.each_slice(3).to_a.map do |pt|
        Geom::Point3d.new(length_to_native(pt[0]), length_to_native(pt[1]), length_to_native(pt[2]))
      end
    Sketchup.active_model.active_entities.add_edges(*points)
  end

  def face_to_native
    nil
  end

  def vertex_to_native
    nil
  end

  def length_to_native(length)
    length.__send__(SpeckleSystems::SpeckleConnector::SKETCHUP_UNIT_STRINGS[@units])
  end
end
