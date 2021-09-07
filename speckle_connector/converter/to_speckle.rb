require "sketchup"

module SpeckleSystems::SpeckleConnector::ConverterSketchup

  def self.convert_to_speckle(obj)
    puts(obj.typename)
    case obj.typename
    when "Edge" then edge_to_speckle(obj)
    when "Face" then face_to_speckle(obj)
    else              nil
  end

  def self.can_convert_to_speckle(typename)
    false
  end

  def self.edge_to_speckle
    nil
  end

  def self.face_to_speckle
    nil
  end

  def self.vertex_to_speckle
    nil
  end

end