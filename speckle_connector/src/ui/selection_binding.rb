# frozen_string_literal: true

require_relative 'binding'
require_relative '../actions/selection_actions/get_selection'

module SpeckleConnector
  module Ui
    SELECTION_BINDING_NAME = 'selectionBinding'

    # Selection binding that provided for DUI.
    class SelectionBinding < Binding
      def commands
        @commands ||= {
          getSelection: Commands::ActionCommand.new(@app, self, Actions::GetSelection)
        }.freeze
      end
    end
  end
end
