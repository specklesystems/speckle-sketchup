# frozen_string_literal: true

module SpeckleConnector3
  module Filters
    # Tag definition for filters for sketchup connector.
    class Tag < Hash
      attr_reader :id
      attr_reader :name
      attr_reader :color

      def initialize(id, name, color)
        super()
        @id = id
        @name = name
        @color = color
        self[:id] = id
        self[:name] = name
        self[:color] = color
      end
    end
  end
end
