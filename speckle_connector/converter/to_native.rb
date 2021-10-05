require "sketchup"

# To Native conversions for the ConverterSketchup
module SpeckleSystems::SpeckleConnector::ToNative
  def convert_to_native
    nil
  end

  def can_convert_to_native(_obj)
    false
  end

  def edge_to_native
    nil
  end

  def face_to_native
    nil
  end

  def vertex_to_native
    nil
  end
end
