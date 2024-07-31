# frozen_string_literal: true

require_relative 'tag'
require_relative 'filter'

module SpeckleConnector3
  module Filters
    # Tag filters for sketchup connector.
    class TagFilter < Filter
      # @return [Array<Tag>] id of the filter
      attr_reader :tags

      # @return [Array<String>] id of the filter
      attr_reader :active_tags

      def initialize(id, name, input, duplicable, tags, active_tags)
        super(id, name, input, duplicable)
        @tags = tags
        @active_tags = active_tags
        self[:tags] = tags
        self[:activeTags] = active_tags
      end
    end
  end
end
