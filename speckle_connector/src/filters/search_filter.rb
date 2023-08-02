# frozen_string_literal: true

require_relative 'filter'

module SpeckleConnector
  module Filters
    # Search filters for sketchup connector.
    # TODO: LATER!
    class SearchFilter < Filter
      # @return [Array<Tag>] id of the filter
      attr_reader :tags

      def initialize(id, name, input, duplicable, tags, active_tags)
        super(id, name, input, duplicable)
        @tags = tags
        @active_tags = active_tags
      end
    end
  end
end
