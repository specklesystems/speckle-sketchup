# frozen_string_literal: true

require_relative '../immutable/immutable'

module SpeckleConnector
  module States
    # Sketchup model state holds information about sketchup related objects like model, layers, materials etc.
    class SketchupState
      include Immutable::ImmutableUtils

      # @return [Sketchup::Model] active model on the sketchup
      attr_reader :sketchup_model

      # @param sketchup_model [Sketchup::Model] active model on the sketchup
      def initialize(sketchup_model)
        @sketchup_model = sketchup_model
      end
    end
  end
end
