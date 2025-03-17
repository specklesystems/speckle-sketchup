# frozen_string_literal: true

require_relative 'base'
require_relative '../constants/type_constants'

module SpeckleConnector3
  module SpeckleObjects
    # A proxy class for an colors.
    class ColorProxy < Base
      SPECKLE_TYPE = SPECKLE_CORE_OTHER_COLOR_PROXY

      # @return [Sketchup::Color]
      attr_reader :sketchup_color

      # @return [Integer, Float]
      attr_reader :value

      # @return [String]
      attr_reader :name

      # @return [Array<String>] The original ids of the objects that has render material
      attr_reader :object_ids

      # @param sketchup_color [Sketchup::Color]
      # @param object_ids [Array<String>]
      # @param application_id [String | NilClass]
      def initialize(sketchup_color, value, object_ids, application_id: nil)
        super(
          speckle_type: SPECKLE_TYPE,
          application_id: application_id,
          id: nil
        )
        @sketchup_color = sketchup_color
        @object_ids = object_ids
        @value = value
        self[:value] = value
        self[:name] = value.to_s
        self[:application_id] = value.to_s
        self[:objects] = object_ids
      end

      # @param object_id [String] application id of the object to add into proxy list
      def add_object_id(object_id)
        object_ids.append(object_id)
        self[:objects] = object_ids
      end
    end
  end
end
