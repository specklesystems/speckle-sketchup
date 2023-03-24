# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../sketchup_model/materials/materials'
require_relative '../sketchup_model/definitions/definitions'

module SpeckleConnector
  module States
    # Sketchup model state holds information about sketchup related objects like model, layers, materials etc.
    class SketchupState
      include Immutable::ImmutableUtils
      # @return [Sketchup::Model] active model on the sketchup
      attr_reader :sketchup_model

      # @return [SketchupModel::Materials] materials by their id
      attr_reader :materials

      # @return [SketchupModel::Definitions] definitions by their guid and name
      attr_reader :definitions

      # @param sketchup_model [Sketchup::Model] active model on the sketchup
      def initialize(sketchup_model)
        @sketchup_model = sketchup_model
        @materials = SketchupModel::Materials.from_sketchup_model(sketchup_model)
        @definitions = SketchupModel::Definitions.from_sketchup_model(sketchup_model)
      end

      # @return [Integer] length units code of the sketchup model.
      #  @example { 0 => 'in', 1 => 'ft', 2 => 'mm', 3 => 'cm', 4 => 'm', 5 => 'yd' }
      def length_units
        sketchup_model.options['UnitsOptions']['LengthUnit']
      end

      def with_materials(new_materials)
        with(:@materials => new_materials)
      end
    end
  end
end
