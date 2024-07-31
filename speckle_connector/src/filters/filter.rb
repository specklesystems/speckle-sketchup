# frozen_string_literal: true


module SpeckleConnector3
  module Filters
    # Base filters for sketchup connector.
    class Filter < Hash
      # @return [String] id of the filter
      attr_reader :id

      # @return [String] name of the filter
      attr_reader :name

      def initialize(id, name)
        super()
        @id = id
        @name = name
        self[:id] = id
        self[:name] = name
      end
    end
  end
end
