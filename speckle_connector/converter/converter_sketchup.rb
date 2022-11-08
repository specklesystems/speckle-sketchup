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
      return edge_to_speckle(obj) if obj.is_a?(Sketchup::Edge)
      return face_to_speckle(obj) if obj.is_a?(Sketchup::Face)
      return component_instance_to_speckle(obj, is_group: true) if obj.is_a?(Sketchup::Group)
      return component_definition_to_speckle(obj) if obj.is_a?(Sketchup::ComponentDefinition)

      component_instance_to_speckle(obj) if obj.is_a?(Sketchup::ComponentInstance)
    end
  end
end
