#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

Sketchup::require 'sketchup.rb'
# Sketchup::require '../TT_Lib2.rb'
require_relative 'system.rb'
require_relative 'c_extension_manager.rb'

#-------------------------------------------------------------------------------

# Root namespace for Thomas Thomassen (ThomThom, TT)
#
# Do not modify or extend!
#
# @since 2.0.0
module SpeckleConnector
  module TT

    ### CONSTANTS ### ------------------------------------------------------------

    # BoundingBox Constants
    # @since 2.0.0

    BB_LEFT_FRONT_BOTTOM    =  0
    BB_RIGHT_FRONT_BOTTOM   =  1
    BB_LEFT_BACK_BOTTOM     =  2
    BB_RIGHT_BACK_BOTTOM    =  3
    BB_LEFT_FRONT_TOP       =  4
    BB_RIGHT_FRONT_TOP      =  5
    BB_LEFT_BACK_TOP        =  6
    BB_RIGHT_BACK_TOP       =  7

    BB_CENTER_FRONT_BOTTOM  =  8
    BB_CENTER_BACK_BOTTOM   =  9
    BB_CENTER_FRONT_TOP     = 10
    BB_CENTER_BACK_TOP      = 11

    BB_LEFT_CENTER_BOTTOM   = 12
    BB_LEFT_CENTER_TOP      = 13
    BB_RIGHT_CENTER_BOTTOM  = 14
    BB_RIGHT_CENTER_TOP     = 15

    BB_LEFT_FRONT_CENTER    = 16
    BB_RIGHT_FRONT_CENTER   = 17
    BB_LEFT_BACK_CENTER     = 18
    BB_RIGHT_BACK_CENTER    = 19

    BB_LEFT_CENTER_CENTER   = 20
    BB_RIGHT_CENTER_CENTER  = 21
    BB_CENTER_FRONT_CENTER  = 22
    BB_CENTER_BACK_CENTER   = 23
    BB_CENTER_CENTER_TOP    = 24
    BB_CENTER_CENTER_BOTTOM = 25

    BB_CENTER_CENTER_CENTER = 26
    BB_CENTER               = 26

    # UI.messagebox Constants
    # @since 2.4.0

    MB_ICONHAND         = 0x00000010
    MB_ICONSTOP         = 0x00000010
    MB_ICONERROR        = 0x00000010
    MB_ICONQUESTION     = 0x00000020
    MB_ICONEXCLAMATION  = 0x00000030
    MB_ICONWARNING      = 0x00000030
    MB_ICONASTERISK     = 0x00000040
    MB_ICONINFORMATION  = 0x00000040
    MB_ICON_NONE        = 80

    MB_DEFBUTTON1 = 0x00000000
    MB_DEFBUTTON2 = 0x00000100
    MB_DEFBUTTON3 = 0x00000200
    MB_DEFBUTTON4 = 0x00000300

    # PolygonMesh
    # @since 2.5.0

    MESH_SHARP        =  0
    MESH_SOFT         =  4
    MESH_SMOOTH       =  8
    MESH_SOFT_SMOOTH  = 12

    # view.draw_points
    # @since 2.5.0

    POINT_OPEN_SQUARE     = 1
    POINT_FILLED_SQUARE   = 2
    POINT_CROSS           = 3
    POINT_X               = 4
    POINT_STAR            = 5
    POINT_OPEN_TRIANGLE   = 6
    POINT_FILLED_TRIANGLE = 7

    # Handle to error message window.
    # @since 2.7.0
    @lib2_update = nil
    def self.lib2_update; @lib2_update; end
    def self.lib2_update=(window); @lib2_update = window; end


    # Defers execution of the given block.
    #
    # @param [Numeric] time
    #
    # @return [Nil]
    # @since 2.5.0
    def self.defer( time = 0 )
      done = false
      timer = UI.start_timer( time, false ) {
        # (i) Unless the timer is stopped before the messagebox it will
        # continue to trigger until the frist messagebox is closed.
        unless done
          done = true
          yield
        end
      }
      nil
    end


    ### LIBRARY ### --------------------------------------------------------------

    # TT_Lib related methods.
    #
    # @since 2.0.0
    module Lib

      # Library version number.
      # @since 2.0.0
      VERSION = PLUGIN_VERSION

      # Library preference key.
      # @since 2.5.0
      PREF_KEY = 'TT_Lib2'.freeze

      # @since 2.8.0
      file = File.expand_path( __FILE__ ) # rubocop:disable SketchupSuggestions/FileEncoding
      file.force_encoding( "UTF-8" ) if file.respond_to?( :force_encoding )
      PATH           = File.dirname( file ).freeze
      PATH_LIBS      = File.join( PATH, 'libraries' ).freeze

      # TT::Lib.cext_manager
      def self.cext_manager; @cext_manager; end
      begin
        @cext_manager = CExtensionManager.new( PATH_LIBS, PLUGIN_VERSION )
        PATH_LIBS_CEXT = @cext_manager.prepare_path.freeze
      rescue CExtensionManager::IncompatibleVersion => error
        unless @compatibility_alert
          # Avoid this message being called for every extension that rely on TT_Lib.
          @compatibility_alert = true
          message = "%{extension_name} version %{version} is not "\
          "compatible with this version of SketchUp and could not be loaded. "\
          "Please check for updates to the extension."
          message %= { extension_name: PLUGIN_NAME, version: PLUGIN_VERSION }
          TT.defer(1.0) {
            UI.messagebox(message)
          }
        end
      end

      # Call this method to check if the installed +TT_Lib+ version is the same
      # or newer than +version+. If it's not then a messagebox will appear
      # informing the user that a newer +TT_Lib+ is required.
      #
      # @param [String] version a string with the minimun version required in
      #   the format 'x.x.x'.
      # @param [String] plugin_name a string describing to the user which plugin
      #   require a newer TT_Lib version.
      #
      # @return [Boolean]
      # @since 2.0.0
      def self.compatible?(version, plugin_name = 'A plugin installed')
        major, minor, revision  = TT::Lib::VERSION.split('.').map { |s| s.to_i }
        min_major, min_minor, min_revision = version.split('.').map { |s| s.to_i }
        return true if major > min_major
        return true if major == min_major && minor > min_minor
        return true if major == min_major && minor == min_minor && revision >= min_revision
        #UI.messagebox("#{plugin_name} requires a newer version, #{version}, of TT_Lib.")
        if TT.lib2_update.nil?
          url = 'http://www.thomthom.net/software/sketchup/tt_lib2/errors/outdated'
          options = {
            :dialog_title => 'TT_Lib² Outdated',
            :scrollable => false, :resizable => false, :left => 200, :top => 200
          }
          w = UI::WebDialog.new( options )
          w.set_size( 500, 300 )
          arguments  = "plugin=#{plugin_name}"
          arguments << "&version=#{TT::Lib::VERSION}"
          arguments << "&minimum=#{version}"
          w.set_url( "#{url}?#{arguments}" )
          w.show
          TT.lib2_update = w
        end
        return false
      end


      # Compiles a list of the current .rb and .rbs files in the library. This is
      # used to verify the integirty of the installation upon first run.
      #
      # @private
      # @return [Nil]
      # @since 2.5.0
      def self.compile_integrity_list
        result = UI.messagebox( <<MSG, MB_OKCANCEL )
This method is only intended for development purposes. Don't mess about with it!
Press Cancel.
MSG
        #'# Silly Sublime Text doesn't handle HereDoc arguments properly.
        return if result == 2 # CANCEL

        files = Dir.glob( File.join(self.path, '*.{rb,rbs}') ).map! { |file|
          File.basename( file )
        }

        File.open( self.integrity_check_file, 'w' ) { |output|
          output.puts( files )
        }
        nil
      end


      # @private
      # @since 2.9.5
      class IntegrityCheck

        attr_reader :unexpected_files, :missing_files

        def initialize( file_with_list_of_expected_files )
          integrity_file = file_with_list_of_expected_files
          @expected_files = IO.readlines( integrity_file ).map! { |file|
            file.strip
          }

          @missing_files = @expected_files.select { |file|
            filename = File.join( PATH, file )
            !File.exist?( filename )
          }

          filter = File.join(PATH, '*.{rb,rbs}' )
          @existing_files = Dir.glob( filter ).map! { |file|
            File.basename( file )
          }
          @unexpected_files = @existing_files - @expected_files
        end

        def ok?
          @missing_files.empty? && @unexpected_files.empty?
        end

        def missing_files?
          !@missing_files.empty?
        end

        def unexpected_files?
          !@unexpected_files.empty?
        end

      end # class IntegrityCheck


      # Called upon startup. If it's the first time this library is loaded a file
      # integrity check is run to ensure all requires files are present, and that
      # there are no old remains in case of an update.
      #
      # @private
      # @return [Boolean]
      # @since 2.5.0
      def self.integrity_check
        version = "VerifiedIntegrity-#{self::VERSION}"
        verified = ::Sketchup.read_default( PREF_KEY, version )
        return true if verified

        integrity = IntegrityCheck.new( self.integrity_check_file )

        if integrity.ok?
          ::Sketchup.write_default( PREF_KEY, version, true )
          true
        else
          message = <<MSG
TT_Lib² appear to be incorrectly installed. Please remove TT_Lib² and then
install it again. If this error message persist, contant the author for
assistance.
MSG
          message.gsub!( /\s+/, ' ' ) # Collapse whitespace.

          if integrity.missing_files?
            missing_files = integrity.missing_files.join("\n")
            message << "\n\nMissing files:\n" << missing_files
          end

          if integrity.unexpected_files?
            unexpected_files = integrity.unexpected_files.join("\n")
            message << "\n\nUnexpected files found:\n" << unexpected_files
          end

          # Defer execution to allow remaining plugins to load.
          TT.defer { UI.messagebox( message, MB_OK ) }
          false
        end

      end


      # Checks for VirtualStore conflict.
      #
      # @private
      # @return [Nil]
      # @since 2.9.0
      def self.virtualstore_check
        return nil unless TT::System.is_windows?
        require 'TT_Lib2/win32.rb'
        plugins_folder = Sketchup.find_support_file( 'Plugins' ) # rubocop:disable SketchupSuggestions/SketchupFindSupportFile
        virtual_folder = TT::System.get_virtual_file( plugins_folder )
        return nil if virtual_folder.nil?
        return nil if plugins_folder == virtual_folder
        return nil unless File.exist?( virtual_folder )
        if Dir.entries( virtual_folder ).to_a.size > 2
          message = <<MSG
TT_Lib² detected that some of the files in SketchUp's plugin folder has ended up
in Window's Virtual Store. It happens because of insufficint permissions for the
plugin folder. Please move the files into the real Plugins folder.
MSG
          message.gsub!( /\s+/, ' ' ) # Collapse whitespace.
          # Defer execution to allow remaining plugins to load.
          TT.defer {
            result = UI.messagebox( message, MB_OKCANCEL )
            if result == IDOK
              UI.openURL( virtual_folder )
            end
          }
        end
        nil
      end


      # Returns the full path to the integrity file.
      #
      # @private
      # @return [Nil]
      # @since 2.5.0
      def self.integrity_check_file
        File.join( self.path, 'integrity_list.dat' )
      end


      # @return [String] The file path where the library is installed.
      # @since 2.0.0
      def self.path
        PATH.dup
      end


      # Debug method to reload the library modules.
      #
      # @param [Boolean] return_files Determines if the method should return
      #   the number of files reloaded or an array of the files reloaded.
      #
      # @return [Integer, Array]
      # @since 2.0.0
      def self.reload( return_files=false )
        original_verbose = $VERBOSE
        $VERBOSE = nil # Mute warnings caused by constant redefining.
        x = Dir.glob( File.join(self.path, '*.{rb,rbs}') ).each { |file|
          load file
        }
        (return_files) ? x : x.length
      ensure
        $VERBOSE = original_verbose
      end

    end # module TT::Lib


    ### MENUS ### ----------------------------------------------------------------

    # If TT's Menu is installed this method will return a custom Menu item
    # instead of the requested root menu.
    #
    # @param [String] name The prefered root menu in Sketchup.
    #
    # @return [Sketchup::Menu]
    # @since 2.0.0
    def self.menu( name )
      if global_variables.include?( :$tt_menu ) && $tt_menu
        $tt_menu
      else
        UI.menu( name )
      end
    end


    ### NAMESPACE ### ------------------------------------------------------------

    # Namespace for plugins to be wrapped into.
    # Example:
    #
    #   require 'TT_Lib2/core.rb'
    #   module TT::Plugins::FooBar
    #     ...
    #   end
    #
    # Reserved for Thomas Thomassen.
    #
    # @since 2.0.0
    module Plugins; end


    ### MACROS ### ---------------------------------------------------------------

    # @param [Integer] number
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.even?(number)
      number % 2 == 0
    end


    # @param [Integer] number
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.odd?(number)
      number % 2 > 0
    end


    # Format the given +time+ into a human readable string.
    #
    # @param [Numeric] time
    #
    # @return [String]
    # @since 2.5.0
    def self.format_time( time )
      time = (time.finite?) ? time : 0.0
      hours = (time / 3600).to_i
      minutes = (time/60 - hours * 60).to_i
      seconds = (time - (minutes * 60 + hours * 3600)).to_i
      if hours > 0 && minutes > 0
        "#{hours}h #{minutes}m #{seconds}s"
      elsif minutes > 0
        "#{minutes}m #{seconds}s"
      else
        "#{seconds}s"
      end
    end


    # Returns the given square meters +area_meters+ in square inches.
    #
    # @param [Numeric] area_meters
    #
    # @return [Numeric]
    # @since 2.5.0
    def self.m2( area_meters )
      ratio = 1.m ** 2
      area_meters * ratio
    end


    # Returns the given square inches +area_inches+ in square meters.
    #
    # @param [Numeric] area_inches
    #
    # @return [Numeric]
    # @since 2.5.0
    def self.to_m2( area_inches )
      ratio = 1.0 / self.m2(1)
      area_inches * ratio
    end


    # @param [Object] object
    #
    # @return [String]
    # @since 2.6.0
    def self.object_id_hex( object )
      "0x%x" % (object.object_id << 1)
    end

    # @param [Array] array
    #
    # @return [Hash]
    # @since 2.6.0
    def self.array_to_hash( array )
      h = {}
      for key, value in array
        h[ key ] = value
      end
      h
    end


    ### ENVIRONMENT ###-----------------------------------------------------------

    # Set up load paths.
    #path = File.join( TT::Lib.path, 'libraries' )
    #$LOAD_PATH << path unless $LOAD_PATH.include?( path )

  end # module TT
end

if SpeckleConnector::TT::System.platform_supported?

  # Check the integrity of the library.
  SpeckleConnector::TT::Lib.integrity_check
  #TT::Lib.virtualstore_check() # Disabled until a better guide can be made.

  # Require remaining modules.
  Dir.glob( File.join(SpeckleConnector::TT::Lib.path, '*.{rb}') ).each { |filename|
    file = __FILE__.dup
    file.force_encoding( "UTF-8" ) if file.respond_to?(:force_encoding)
    unless File.basename( filename ) == File.basename( file )
      relative_file = File.join( SpeckleConnector::TT::Lib.path, File.basename( filename ) )
      require( relative_file )
    end
  }

else

  # Disable the extension if it's not supported by the platform. This is done to
  # avoid potential crashes when loading the binaries.
  #if Sketchup.respond_to?(:extensions)
  #  extension = Sketchup.extensions[TT::Lib::PLUGIN_NAME]
  #  extension.uncheck
  #end
  # Alert the user that the extension is not compatible with the running system.
  message = "#{SpeckleConnector::TT::Lib::PLUGIN_NAME} is not supported for this platform."
  UI.messagebox(message)

end # if TT::System.platform_supported?
