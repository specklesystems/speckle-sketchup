# frozen_string_literal: true

require_relative 'speckle_object'

module SpeckleConnector
  module SpeckleObjects
    # Base speckle geometry object
    class SpeckleGeometryObject < SpeckleObject
      ATTRIBUTES = {
        speckle_type: String,
        units: String
      }.freeze

      # @return [String] units of the sketchup.
      attr_reader :units

      # @param speckle_type [String] type of the speckle object
      # @param units [String] units of the Sketchup.
      # @param **other_parameters [Hash{Symbol=>Object}] other parameters to check and serialize.
      def initialize(speckle_type, units, **other_parameters)
        @units = units
        super(speckle_type, **{ units: units, **other_parameters })
      end

      private

      def attribute_types
        ATTRIBUTES
      end
    end
  end
end
