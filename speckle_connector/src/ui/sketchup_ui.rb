# frozen_string_literal: true

module SpeckleConnector
  module Ui
    # An interface to Sketchup user interface. This object controls the menu `Extensions->Speckle` in Sketchup's menu,
    # the Speckle toolbar and sending message to the user via Sketchup.
    class SketchupUi
      MENU_TITLE = 'Speckle'
      BEFORE_NEVER_SHOWN = -1

      # @return [Sketchup::Menu] the menu of the Speckle
      attr_reader :speckle_menu

      # @return [UI::Toolbar] the Speckle toolbar
      attr_reader :speckle_toolbar

      def initialize
        @speckle_menu = UI.menu.add_submenu(MENU_TITLE)
        @speckle_toolbar = UI::Toolbar.new(MENU_TITLE)
        @speckle_toolbar.show if @speckle_toolbar.get_last_state == BEFORE_NEVER_SHOWN
      end
    end
  end
end
