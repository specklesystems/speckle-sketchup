#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'system.rb'
require_relative 'win32.rb'

module SpeckleConnector
  # @note Originally named +TT::Sketchup+ but renamed to +TT::SketchUp+ to avoid
  # namespace confusion over +Sketchup+ for the +TT+ namespace. This was done in
  # version 2.5.4.
  #
  # @since 2.5.0
  module TT::SketchUp

    # Support for +view.draw+ with filled polygons that uses +view.drawing_color+.
    # @since 2.5.0
    COLOR_GL_POLYGON = 0

    # +view.draw+ and +view.draw2d+ makes use of +Sketchup::Color.alpha+.
    # @since 2.5.0
    COLOR_ALPHA = 1

    # wysiwyg flag for +Sketchup::Model.raytest+
    # @since 2.5.0
    RAYTEST_WYSIWYG = 2

    # When a feature cannot be determined by feature testing, this method can be
    # used. It check features against known version numbers.
    #
    # @param [Symbol] feature_id
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.support?(feature_id)
      case feature_id
      when  COLOR_GL_POLYGON,
        COLOR_ALPHA,
        RAYTEST_WYSIWYG
        # 4811 Windows
        # 4810 OSX
        self.newer_than?( 8,0,4810 )
      end
    end

    # Returns +true+ is the running SketchUp version is newer or equal to the
    # required minimum.
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.newer_than?(min_major, min_minor, min_revision)
      major, minor, revision = self.version
      return true if major > min_major
      return true if major == min_major && minor > min_minor
      return true if major == min_major && minor == min_minor && revision >= min_revision
      return false
    end

    # Returns the SketchUp version as an Array of Integers.
    #
    # @return [Array]
    # @since 2.5.0
    def self.version
      Sketchup.version.split('.').map { |str| str.to_i }
    end

    # Attempt to let SketchUp update its UI.
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.refresh
      if TT::System::PLATFORM_IS_WINDOWS
        TT::Win32.refresh_sketchup
        true
      else
        # Tough luck! :(
        false
      end
    end

    # Activates the main SketchUp window.
    #
    # @return [Boolean]
    # @since 2.6.0
    def self.activate_main_window
      if TT::System::PLATFORM_IS_WINDOWS
        TT::Win32.activate_sketchup_window
        true
      else
        # Tough luck! :(
        false
      end
    end

  end # module TT::SketchUp
end
