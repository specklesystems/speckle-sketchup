#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'gui.rb'
require_relative 'window.rb'
require_relative 'toolwindow.rb'

module SpeckleConnector
  # (i) Alpha stage. Very likely to be subject to change!
  #
  # @example
  #   w = TT::GUI::Toolbar.new
  #   w.show_window
  #
  # @deprecated Not in use
  # @since 2.5.0
  class TT::GUI::Toolbar < TT::GUI::ToolWindow


    # @return [Nil]
    # @since 2.5.0
    def initialize(*args)
      super
      self.add_style( File.join(TT::Lib.path, 'webdialog', 'css', 'wnd_toolbar.css') )
    end

    def add_control( control )
      raise ArgumentError unless button.is_a?( TT::GUI::Button )
    end


  end # module TT::GUI::Window
end
