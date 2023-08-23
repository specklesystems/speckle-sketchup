#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'gui.rb'
require_relative 'sketchup.rb'

module SpeckleConnector
  # Creates a wrapper class that simulates a modal environment for the window. It
  # is not truly modal because of limitations of the API under OSX, but uses a tool
  # class to prevent the user from manipulating the model while the window is open.
  # If the user should activate another tool it acts as if the user used the Close
  # or cancel button.
  #
  # @todo Prevent other Windows from opening (?)
  #
  # @since 2.4.0
  class TT::GUI::ModalWrapper

    @@open_window = nil

    # @param [TT::GUI::Window] window
    #
    # @since 2.4.0
    def initialize(window)
      @window = window
    end

    # @private
    # @since 2.4.0
    def activate
      #puts "T:activate - #{@@open_window}"
      Sketchup.active_model.active_view.invalidate
      @@open_window = @window
      @window.show_window
    end

    # @private
    # @since 2.4.0
    def deactivate(view)
      #puts 'T:deactivate'
      #puts "> visible? #{@window.visible?}"
      #puts "> closing? #{@window.closing?}"
      @window.close unless @window.closing?
      @@open_window = nil
      view.invalidate
    end

    # @private
    # @since 2.5.0
    def resume(view)
      view.invalidate
    end

    # @private
    # @since 2.4.0
    def onLButtonDown(flags, x, y, view)
      UI.beep
      @window.bring_to_front
    end

    # @private
    # @since 2.4.0
    def getMenu(menu)
      # Suppress the context menu
      menu.add_item('Close Dialog') {
        @window.close
      }
    end

    # @private
    # @since 2.4.0
    def onCancel(reason, view)
      #puts "T:onCancel: reason #{reason.to_s}"
    end

    if TT::SketchUp::support?( TT::SketchUp::COLOR_ALPHA )
      # Dim the SketchUp viewport while the modal window is open.
      # @private
      # @since 2.5.0
      def draw(view)
        pts = [
          [0,0,0],
          [view.vpwidth,0,0],
          [view.vpwidth,view.vpheight,0],
          [0,view.vpheight,0]
        ]
        view.drawing_color = Sketchup::Color.new(0,0,0,128)
        view.draw2d( GL_QUADS, pts )
      end
    end


    ### Public Methods ###


    # Displays the modal window as long as there are no other modal windows open.
    # It only handles +TT::GUI::Window+ objects that uses the +ModalWrapper+ class.
    #
    # @since 2.4.0
    def show
      #puts 'T:show'
      @closing = false
      if @@open_window
        UI.beep
        @@open_window.bring_to_front
      else
        Sketchup.active_model.tools.push_tool( self )
      end
    end

    # Closes the modal window.
    #
    # @since 2.4.0
    def close
      #puts 'T:close'
      #puts caller.join("\r\n")
      # Prevent popping the tool multiple times. This worked fine in older SketchUp
      # versions, but regressed in SU2014 where it would then cause a crash.
      return false if @closing
      @closing = true
      Sketchup.active_model.tools.pop_tool
      true
    end

  end # class TT::GUI::ModalWrapper
end
