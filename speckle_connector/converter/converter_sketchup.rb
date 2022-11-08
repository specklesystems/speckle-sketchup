# frozen_string_literal: true

require 'sketchup'
require 'speckle_connector/converter/to_speckle'
require 'speckle_connector/converter/to_native'

module SpeckleConnector
  SKETCHUP_UNIT_STRINGS = { 'm' => 'm', 'mm' => 'mm', 'ft' => 'feet', 'in' => 'inch', 'yd' => 'yard',
                            'cm' => 'cm' }.freeze
  public_constant :SKETCHUP_UNIT_STRINGS
  class ConverterSketchup
    include ToNative
    include ToSpeckle

    attr_accessor :units, :component_defs, :registry, :entity_observer

    def initialize(units = 'm')
      @units = units
      @component_defs = {}
      # @registry = Sketchup.active_model.attribute_dictionary("speckle_id_registry", true)
      # @entity_observer = SpeckleEntityObserver.new
    end

    def convert_to_speckle(obj)
      case obj.is_a?
      when Sketchup::Edge then edge_to_speckle(obj)
      when Sketchup::Face then face_to_speckle(obj)
      when Sketchup::Group then component_instance_to_speckle(obj, is_group: true)
      when Sketchup::ComponentDefinition then component_definition_to_speckle(obj)
      when Sketchup::ComponentInstance then component_instance_to_speckle(obj)
      else
        raise ArgumentError 'Object type is not supported!'
      end
    end
  end
end
