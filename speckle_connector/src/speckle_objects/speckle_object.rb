# frozen_string_literal: true

require_relative 'available_speckle_objects'
require_relative '../typescript/typescript_object'

module SpeckleConnector
  module SpeckleObjects
    # Base speckle object
    class SpeckleObject < Typescript::TypescriptObject
      ATTRIBUTES = {
        speckle_type: String
      }.freeze

      # @return [String] type of the Speckle Object.
      attr_reader :speckle_type

      def initialize(speckle_type, **other_parameters)
        raise ArgumentError 'Speckle type is not supported.' unless AVAILABLE_SPECKLE_OBJECTS.include?(speckle_type)

        super(speckle_type: speckle_type, **other_parameters)
        @speckle_type = speckle_type
      end

      def attribute_types
        ATTRIBUTES
      end
    end
  end
end
