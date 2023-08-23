#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative '../TT_Lib2.rb'
require_relative 'system.rb'

module SpeckleConnector
  # @since 2.5.0
  module TT::Win32

    require_relative '../TT_Lib2/win32/win32_constants.rb'
    include TT::Win32::Constants

    if RUBY_VERSION.to_f < 2.7
      require_relative '../TT_Lib2/win32/win32_win32api.rb'
      extend Win32Win32APIImpl
      include Win32Win32APIImpl # Expose the Win32 constants like old versions did.
    else
      require_relative '../TT_Lib2/win32/win32_fiddle.rb'
      extend Win32FiddleImpl
    end


    # @example TT::Win32.get_folder_path( TT::Win32::CSIDL_LOCAL_APPDATA )
    #
    # @param [Integer] csidl
    #
    # @return [String|Nil]
    # @since 2.9.0
    def self.get_folder_path( csidl )
      path = self.get_folder_path_utf16( csidl )
      self.utf16_to_utf8( path )
    end


    # @example TT::Win32.get_folder_path_ansi( TT::Win32::CSIDL_LOCAL_APPDATA )
    #
    # @param [Integer] csidl
    #
    # @return [String|Nil]
    # @since 2.9.0
    def self.get_folder_path_ansi( csidl )
      path = self.get_folder_path_utf16( csidl )
      self.utf16_to_ansi( path )
    end


    # @example TT::Win32.get_short_folder_path( TT::Win32::CSIDL_LOCAL_APPDATA )
    #
    # @param [Integer] csidl
    #
    # @return [String|Nil]
    # @since 2.9.0
    def self.get_short_folder_path( csidl )
      path = self.get_short_folder_path_utf16( csidl )
      self.utf16_to_utf8( path )
    end


    # @example TT::Win32.get_short_folder_path_ansi( TT::Win32::CSIDL_LOCAL_APPDATA )
    #
    # @param [Integer] csidl
    #
    # @return [String|Nil]
    # @since 2.9.0
    def self.get_short_folder_path_ansi( csidl )
      path = self.get_short_folder_path_utf16( csidl )
      self.utf16_to_ansi( path )
    end


    # @param [String] utf16_string
    #
    # @return [String|Nil]
    # @since 2.9.0
    def self.utf16_to_ansi( utf16_string )
      self.utf16_to_codepage( utf16_string, CP_ACP )
    end


    # @param [String] utf16_string
    #
    # @return [String|Nil]
    # @since 2.9.0
    def self.utf16_to_utf8( utf16_string )
      self.utf16_to_codepage( utf16_string, CP_UTF8 )
    end


    # @param [String] file
    #
    # @return [String]
    # @since 2.9.0
    def self.is_virtualized?( file )
      virtualfile = self.get_virtual_path( file )
      !virtualfile.nil? && File.exist?( virtualfile )
    end


    # @param [String] file
    #
    # @return [String, Nil]
    # @since 2.9.0
    def self.get_virtual_file( file )
      filename = File.basename( file )
      filepath = File.dirname( file )
      # Verify file exists.
      unless File.exist?( file )
        raise IOError, "The file '#{file}' does not exist."
      end
      if ENV['LOCALAPPDATA'].nil?
        return nil
      end
      virtualstore = File.join( ENV['LOCALAPPDATA'], 'VirtualStore' )
      path = filepath.split(':')[1]
      virtual_path = File.join( virtualstore, path, filename )
      File.expand_path( virtual_path )
    end

  end if TT::System.is_windows? # module TT::Win32
end

