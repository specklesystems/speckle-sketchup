# frozen_string_literal: true

require_relative '../immutable/immutable'

module SpeckleConnector
  module States
    # Sketchup model state holds information about sketchup related objects like model, layers, materials etc.
    class SketchupState
      include Immutable::ImmutableUtils
      # @return [Sketchup::Model] active model on the sketchup
      attr_reader :sketchup_model

      attr_reader :attached_observers

      # @param sketchup_model [Sketchup::Model] active model on the sketchup
      def initialize(sketchup_model)
        @sketchup_model = sketchup_model
        @attached_observers = Immutable::EmptyHash
      end

      # @return [Integer] length units code of the sketchup model.
      #  @example { 0 => 'in', 1 => 'ft', 2 => 'mm', 3 => 'cm', 4 => 'm', 5 => 'yd' }
      def length_units
        sketchup_model.options['UnitsOptions']['LengthUnit']
      end
    end
  end
end
