# frozen_string_literal: true

require_relative '../../ui_data/components/selections/list_selection_item'

module SpeckleConnector3
  module Filters
    module Send
      # Everything filter for sketchup connector to send all.
      class EverythingFilter < UiData::Components::Selections::ListSelectionItem
        def initialize
          super('everything', 'Everything', nil,
                'All supported objects in the currently opened file.')
        end

        def self.from_json(_data)
          EverythingFilter.new
        end

        def check_expiry(_ids)
          true
        end
      end
    end
  end
end
