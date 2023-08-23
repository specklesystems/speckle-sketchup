#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative '../../TT_Lib2.rb'
require_relative '../system.rb'

module SpeckleConnector
  # @since 2.5.0
  module TT::Win32
    # @since 2.13.0
    module Win32Win32APIImpl

      require 'TT_Lib2/win32/win32_constants.rb'
      include TT::Win32::Constants

      if !file_loaded?( __FILE__ )

        if RUBY_VERSION.to_i < 2
          require File.join( TT::Lib::PATH_LIBS_CEXT, 'tt_api' )
        elsif RUBY_VERSION.to_i == 2

          # Compatibility shim. Since Ruby 2.0 ships with the standard library which
          # include Win32API it will be used instead. But that means some tweaks
          # must be used to make the two libs interchangeable.
          # This is just a quick fix to make old code compatible without requiring to
          # recompile for every new SketchUp release where binary C extensions are
          # made incompatible. New extensions should use `fiddle` instead.
          require File.join( TT::Lib::PATH, 'win32_shim.rb' )
          require "Win32API"
          class API
            def initialize(function, input, output, library)
              @api = ::Win32API.new(library, function, input, output)
            end
            def call(*args)
              args.map! { |arg| arg.nil? ? 0 : arg }
              @api.call(*args)
            end
          end # class API

        else

          raise "unsupported SketchUp version: #{Sketchup.version}"

        end # if RUBY_VERSION

        # Windows Functions
        # L = Long (includes hwnd)
        # I = Integer
        # P = Pointer
        # V = Void
        GetAncestor         = API.new('GetAncestor' , 'LI', 'L', 'user32')

        # http://msdn.microsoft.com/en-us/library/ms646292%28v=vs.85%29.aspx
        # http://blogs.msdn.com/b/oldnewthing/archive/2008/10/06/8969399.aspx
        #
        # The return value is the handle to the active window attached to the calling
        # thread's message queue. Otherwise, the return value is NULL.
        #
        # To get the handle to the foreground window, you can use GetForegroundWindow.
        GetActiveWindow     = API.new('GetActiveWindow', '', 'L', 'user32')

        # http://msdn.microsoft.com/en-us/library/ms646311%28v=vs.85%29.aspx
        SetActiveWindow     = API.new('SetActiveWindow', 'L', 'L', 'user32')

        SetWindowPos        = API.new('SetWindowPos' , 'LLIIIII', 'I', 'user32')
        SetWindowLong       = API.new('SetWindowLong', 'LIL', 'L', 'user32')
        GetWindowLong       = API.new('GetWindowLong', 'LI' , 'L', 'user32')
        GetWindowText       = API.new('GetWindowText', 'LPI', 'I', 'user32')
        GetWindowTextLength = API.new('GetWindowTextLength', 'L', 'I', 'user32')
        include TT::Win32::Constants

        # http://msdn.microsoft.com/en-us/library/ms644943%28v=vs.85%29.aspx
        PeekMessage         = API.new('PeekMessage' , 'PLIII', 'I', 'user32')

        OutputDebugString   = API.new('OutputDebugString', 'P', 'V', 'kernel32')

        if RUBY_VERSION.to_i < 2
          # Raises an error in Ruby 2.2 because it uses Fiddle directly while 2.0
          # used DL. It didn't work in 2.0, but it didn't raise an error.
          EnumThreadWindows = API.new('EnumThreadWindows', 'LKP', 'I', 'user32')
        end

        # Process.pid returns the same value as GetCurrentProcessId.
        #GetCurrentProcessId = API.new('GetCurrentProcessId' , '', 'L', 'kernel32')
        GetCurrentThreadId = API.new('GetCurrentThreadId', '', 'L', 'kernel32')

        # Shell functons.
        SHGetFolderPath = API.new('SHGetFolderPathW', 'LILLP', 'I', 'shell32')

        # File functions.
        GetShortPathName = API.new('GetShortPathNameW', 'PPL', 'L', 'kernel32')

        # String encoding.
        MultiByteToWideChar = API.new('MultiByteToWideChar', 'LLPIPI', 'I', 'kernel32')
        WideCharToMultiByte = API.new('WideCharToMultiByte', 'LLPIPIPP', 'I', 'kernel32')
      end
      # There is a limit to how many API object can be defined. So these are only
      # created at the start of the session. TT::Lib.reload will not update any
      # changes to the section that defines the API calls. SketchUp needs to be
      # restarted.
      file_loaded( __FILE__ )


      # (i)
      # To obtain a window's owner window, instead of using GetParent, use GetWindow
      # with the GW_OWNER flag. To obtain the parent window and not the owner,
      # instead of using GetParent, use GetAncestor with the GA_PARENT flag.


      #(i)
      # FindWindowLike
      # http://support.microsoft.com/kb/147659

      # EnumChildWindows
      # http://msdn.microsoft.com/en-us/library/ms633494%28v=vs.85%29.aspx
      # http://stackoverflow.com/questions/3327666/win32s-findwindow-can-find-a-particular-window-with-the-exact-title-but-what


      # If one creates too many Win32::API::Callbacks one get the following error:
      # +Error: #<Win32::API::Error: too many callbacks are defined.>+ This presents
      # a problem when you need to enumerate windows.
      #
      # Use this class to avoid this.
      #
      #  param = 'SketchUpMainWindow'
      #  enumWindowsProc = EnumWindowsProc.new(param) { |handle|
      #    # Return 0 (FALSE) to stop enumeration or 1 (TRUE) to proceed.
      #  }
      #  EnumThreadWindows.call(threadId, enumWindowsProc.callback, param)
      class EnumWindowsProc

        attr_reader( :param )

        @@enumThreadWndProc = API::Callback.new('LP', 'I'){ |hwnd, param|
          if @@callbacks.key?( param )
            @@callbacks[ param ].call( hwnd )
          end
        }
        @@callbacks = {}

        # @param [String] param - the +param+ argument this callback should repond to.
        def initialize( param, &block )
          @param = param.dup
          @@callbacks[ param ] = block
        end

        def callback
          @@enumThreadWndProc
        end

        def destroy_callback( param )
          @@callbacks.delete?( param )
        end

      end if RUBY_VERSION.to_i < 2 # class EnumThreadWndProc


      # Returns the window handle of the SketchUp window for the input queue of the
      # calling ruby method.
      #
      # @return [Integer] Returns a window handle on success or +nil+ on failure
      # @since 2.5.0
      if RUBY_VERSION.to_i < 2
        def get_sketchup_window
          threadId = GetCurrentThreadId.call
          hwnd = 0
          param = 'SketchUpMainWindow'
          enumWindowsProc = EnumWindowsProc.new( param ) { |handle|
            hwnd = GetAncestor.call( handle, GA_ROOTOWNER )
            0
          }
          EnumThreadWindows.call( threadId, enumWindowsProc.callback, param )
          hwnd
        end
      else
        def get_sketchup_window
          Shim.get_main_window_handle
        end
      end


      # If the function succeeds, the return value is the handle to the window that
      # was previously active.
      #
      # If the function fails, the return value is NULL. To get extended error
      # information, call GetLastError.
      #
      # @return [Integer]
      # @since 2.6.0
      def activate_sketchup_window
        hwnd = get_sketchup_window
        return false unless hwnd
        SetActiveWindow.call( hwnd )
      end


      # @param [Integer] hwnd
      #
      # @return [String|Nil]
      # @since 2.5.0
      def get_window_text(hwnd)
        # Create a string buffer for the window text.
        buf_len = GetWindowTextLength.call(hwnd)
        return nil if buf_len == 0
        str = ' ' * (buf_len + 1)
        # Retreive the text.
        result = GetWindowText.call(hwnd, str, str.length)
        return nil if result == 0
        str.strip
      end


      # @private
      #
      # @param [Integer] csidl
      #
      # @return [String|Nil]
      # @since 2.9.0
      def get_folder_path_utf16( csidl )
        lpszLongPath = ' ' * ( MAX_PATH * 2 )
        SHGetFolderPath.call( nil, csidl, nil, SHGFP_TYPE_CURRENT, lpszLongPath )
        lpszLongPath
      end


      # @private
      #
      # @param [Integer] csidl
      #
      # @return [String|Nil]
      # @since 2.9.0
      def get_short_folder_path_utf16( csidl )
        lpszLongPath = get_folder_path_utf16( csidl )
        lpszShortPath_len = GetShortPathName.call( lpszLongPath, nil, 0 )
        lpszShortPath = ' ' * ( lpszShortPath_len * 2 )
        GetShortPathName.call( lpszLongPath, lpszShortPath, lpszShortPath_len )
        lpszShortPath
      end


      # @param [String] utf8_string
      #
      # @return [String|Nil]
      # @since 2.9.0
      def utf8_to_utf16( utf8_string )
        utf16_string_len = MultiByteToWideChar.call( CP_UTF8, 0,
                                                     "#{utf8_string}\0", -1, nil, 0 )
        utf16_string = ' ' * ( utf16_string_len * 2 )
        MultiByteToWideChar.call( CP_UTF8, 0,
                                  "#{utf8_string}\0", -1, utf16_string, utf16_string_len )
        utf16_string
      end


      # @private
      #
      # @param [Integer] codepage
      #
      # @return [String|Nil]
      # @since 2.9.0
      def utf16_to_codepage( utf16_string, codepage )
        num_bytes = WideCharToMultiByte.call( codepage, 0,
                                              utf16_string, -1, nil, 0, nil, nil )
        out_buffer = ' ' * num_bytes
        WideCharToMultiByte.call( codepage, 0,
                                  utf16_string, -1, out_buffer, num_bytes, nil, nil )
        out_buffer.strip.strip # First strip doesn't strip NULL character.
      end


      # Call after webdialog.show to change the window into a toolwindow. Spesify the
      # window title so the method can verify it changes the correct window.
      #
      # @param [String] window_title
      #
      # @return [Nil]
      # @since 2.5.0
      def make_toolwindow_frame(window_title)
        # Retrieves the window handle to the active window attached to the calling
        # thread's message queue.
        hwnd = GetActiveWindow.call
        return nil if hwnd == 0

        # Verify window text as extra security to ensure it's the correct window.
        buf_len = GetWindowTextLength.call(hwnd)
        return nil if buf_len == 0

        str = ' ' * (buf_len + 1)
        result = GetWindowText.call(hwnd, str, str.length)
        return nil if result == 0

        return nil unless str.strip == window_title.strip

        # Set frame to Toolwindow
        style = GetWindowLong.call(hwnd, GWL_EXSTYLE)
        return nil if style == 0

        new_style = style | WS_EX_TOOLWINDOW
        result = SetWindowLong.call(hwnd, GWL_EXSTYLE, new_style)
        return nil if result == 0

        # Remove and disable minimze and maximize
        # http://support.microsoft.com/kb/137033
        style = GetWindowLong.call(hwnd, GWL_STYLE)
        return nil if style == 0

        style = style & ~WS_MINIMIZEBOX
        style = style & ~WS_MAXIMIZEBOX
        result = SetWindowLong.call(hwnd, GWL_STYLE,  style)
        return nil if result == 0

        # Refresh the window frame
        # (!) SWP_NOZORDER | SWP_NOOWNERZORDER
        flags = SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE
        result = SetWindowPos.call(hwnd, 0, 0, 0, 0, 0, flags)
        result != 0
      end


      # Removes the Min and Max button.
      #
      # Call after webdialog.show to change the window into a toolwindow. Spesify the
      # window title so the method can verify it changes the correct window.
      #
      # @param [String] window_title
      #
      # @return [Nil]
      # @since 2.6.0
      def window_no_resize( window_title )
        # Retrieves the window handle to the active window attached to the calling
        # thread's message queue.
        hwnd = GetActiveWindow.call
        return nil if hwnd == 0

        # Verify window text as extra security to ensure it's the correct window.
        buf_len = GetWindowTextLength.call(hwnd)
        return nil if buf_len == 0

        str = ' ' * (buf_len + 1)
        result = GetWindowText.call(hwnd, str, str.length)
        return nil if result == 0

        return nil unless str.strip == window_title.strip

        # Remove and disable minimze and maximize
        # http://support.microsoft.com/kb/137033
        style = GetWindowLong.call(hwnd, GWL_STYLE)
        return nil if style == 0

        style = style & ~WS_MINIMIZEBOX
        style = style & ~WS_MAXIMIZEBOX
        result = SetWindowLong.call(hwnd, GWL_STYLE,  style)
        return nil if result == 0

        # Refresh the window frame
        # (!) SWP_NOZORDER | SWP_NOOWNERZORDER
        flags = SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE
        result = SetWindowPos.call(hwnd, 0, 0, 0, 0, 0, flags)
        result != 0
      end


      # Allows the SketchUp process to process it's queued messages. Avoids whiteout.
      #
      # @return [Boolean] if message is available
      # @since 2.5.0
      def refresh_sketchup
        # If a message is available, the return value is nonzero.
        # If no messages are available, the return value is zero.
        PeekMessage.call( nil, nil, 0, 0, PM_NOREMOVE ) != 0
      end

    end

  end if TT::System.is_windows? # module TT::Win32
end

