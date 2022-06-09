require "sketchup"
require "speckle_connector/converter/to_speckle"
require "speckle_connector/converter/to_native"

module SpeckleSystems::SpeckleConnector
  SKETCHUP_UNIT_STRINGS = { "m" => "m", "mm" => "mm", "ft" => "feet", "in" => "inch", "yd" => "yard", "cm" => "cm" }.freeze
  public_constant :SKETCHUP_UNIT_STRINGS
  class ConverterSketchup
    include ToNative
    include ToSpeckle

    attr_accessor :units, :component_defs, :registry, :entity_observer

    def initialize(units = "m")
      @units = units
      @component_defs = {}
      # @registry = Sketchup.active_model.attribute_dictionary("speckle_id_registry", true)
      # @entity_observer = SpeckleEntityObserver.new
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
  end
end
