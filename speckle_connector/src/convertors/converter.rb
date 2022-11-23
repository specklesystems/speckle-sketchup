# frozen_string_literal: true

module SpeckleConnector
  module Converters
    # Helper class to convert geometries between server and Sketchup.
    class Converter
      attr_accessor :units, :definitions, :registry, :entity_observer, :sketchup_model

      def initialize(sketchup_model)
        @sketchup_model = sketchup_model
        su_unit = @sketchup_model.options['UnitsOptions']['LengthUnit']
        @units =  Converters::SKETCHUP_UNITS[su_unit]
        @definitions = {}
        # @registry = Sketchup.active_model.attribute_dictionary("speckle_id_registry", true)
        # @entity_observer = SpeckleEntityObserver.new
      end
    end
  end
end
