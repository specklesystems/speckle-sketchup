require "sketchup"
require "speckle_connector/converter/to_speckle"
require "speckle_connector/converter/to_native"

module SpeckleSystems::SpeckleConnector
  class ConverterSketchup
    include ToNative
    include ToSpeckle
    
    SKETCHUP_UNIT_STRINGS = { "m" => "m", "mm" => "mm", "ft" => "feet", "in" => "inch", "yd" => "yard" }.freeze
    public_constant :SKETCHUP_UNIT_STRINGS

    attr_accessor :units, :component_defs

    def initialize(units = "m")
      @units = units
      @component_defs = {}
    end

    def convert_to_speckle(obj)
      case obj.typename
      when "Edge" then edge_to_speckle(obj)
      when "Face" then face_to_speckle(obj)
      when "Group" then component_instance_to_speckle(obj, is_group: true)
      when "ComponentDefinition" then component_definition_to_speckle(obj)
      when "ComponentInstance" then component_instance_to_speckle(obj)
      else nil
      end
    end

    def convert_to_native(obj)
      case obj.typename
      when "Edge" then edge_to_native(obj)
      when "Face" then face_to_native(obj)
      else nil
      end
    end
  end
end
