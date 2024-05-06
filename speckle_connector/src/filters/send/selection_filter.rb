# frozen_string_literal: true

require_relative '../../ui_data/components/selections/list_selection_item'

module SpeckleConnector
  module Filters
    module Send
      # Selection filter for sketchup connector to send all.
      class SelectionFilter < UiData::Components::Selections::ListSelectionItem
        DEFAULT_SUMMARY = 'User based selection filter. UI should replace this summary with the selection info summary!'

        # @return [Array<Integer>] object ids that logged into selection filter.
        attr_reader :selected_object_ids

        def initialize(selected_object_ids, summary = DEFAULT_SUMMARY)
          super('selection', 'Selection', nil, summary)
          @selected_object_ids = selected_object_ids
          self[:selectedObjectIds] = selected_object_ids
        end

        def check_expiry(ids)
          selected_object_ids.intersection(ids.to_a).any?
        end

        def self.from_json(_data)
          SelectionFilter.new([])
        end

        def self.read_from_document(data)
          SelectionFilter.new(data['selectedObjectIds'], data['summary'])
        end

        def self.from_ui_data(data)
          # FIXME: Solve inconsistency! UI send data as hash which should be array
          SelectionFilter.new(data['selectedObjectIds'].values, data['summary'])
        end
      end
    end
  end
end
