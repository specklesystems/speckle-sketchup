#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative '../TT_Lib2.rb'

# ...
#
# @since 2.4.0
module SpeckleConnector
  module TT::System

    # @since 2.5.0
    PLATFORM_IS_OSX     = (Object::RUBY_PLATFORM =~ /darwin/i) ? true : false

    # @since 2.5.0
    PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX

    # @since 2.5.5
    TEMP_PATH = File.expand_path( ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] ).freeze

    # @return [Boolean]
    # @since 2.4.0
    def self.is_osx?
      PLATFORM_IS_OSX
    end

    # @return [Boolean]
    # @since 2.5.0
    def self.is_windows?
      PLATFORM_IS_WINDOWS
    end

    # @param [String] filename
    #
    # @return [String, Nil]
    # @since 2.9.0
    def self.get_virtual_file( filename )
      if TT::System.is_windows?
        TT::Win32.get_virtual_file( filename )
      else
        nil
      end
    end

    # @return [Array<Integer, Integer, Integer>]
    # @since 2.9.15
    def self.platform_version
      if PLATFORM_IS_OSX
        %x(sw_vers -productVersion).chop.split('.').map { |x| x.to_i }
      else
        raise NotImplementedError
      end
    end

    # @return [Boolean]
    # @since 2.9.15
    def self.platform_supported?
      if TT::System.is_osx?
        min_major, min_minor = [10, 7]
        version = self.platform_version
        return true if version.x > min_major
        return true if version.x == min_major && version.y >= min_minor
        false
      else
        true
      end
    end

    # Returns path to the user's local data path.
    #
    # @example
    #   TT::System.local_data_path
    #
    # @return [String,Nil]
    # @since 2.9.0
    def self.local_data_path
      if PLATFORM_IS_WINDOWS
        path = ENV['LOCALAPPDATA']
        # Ruby 1.8 cannot handle paths with non-ASCII characters. If the ENV
        # variable returns a path that Ruby cannot find, try to find it using
        # the Win32 API.
        if path.nil? || !File.exist?( path )
          path = TT::Win32.get_short_folder_path_ansi(
            TT::Win32::CSIDL_LOCAL_APPDATA )
        end
      else
        # http://sketchucation.com/forums/viewtopic.php?f=180&t=52730&p=482216#p482211
        #
        # Sketchup.find_support_file('Plugins') might not be reliable. So look for
        # 'OldColors' folder instead. This should give a path in the User folder
        # on SketchUp 8 and older as well as SketchUp 13.
        #
        # Because we don't know what future SketchUp versions does we look for
        # 'Plugins' last, as since SketchUp 2013 the folder should be in the user
        # folder.
        paths = ['OldColors', 'Plugins']
        sketchup_path = paths.find { |path|
          Sketchup.find_support_file( path ) # rubocop:disable SketchupSuggestions/SketchupFindSupportFile
        }
        path = File.join( sketchup_path, '..', '..' )
        File.expand_path( path )
      end
      path
    end

    # Returns path to the user's temp path.
    #
    # @return [String]
    # @since 2.4.0
    def self.temp_path
      TEMP_PATH.dup
    end

  end # module TT::System
end

