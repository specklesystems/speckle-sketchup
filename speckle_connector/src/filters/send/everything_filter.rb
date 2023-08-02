# frozen_string_literal: true

require_relative '../../ui_data/selections/list_selection_item'

module SpeckleConnector
  module Filters
    module Send
      # Everything filter for sketchup connector to send all.
      class EverythingFilter < UiData::Selections::ListSelectionItem
        def initialize
          super('everything', 'Everything', nil)
        end
      end
    end
  end
end
