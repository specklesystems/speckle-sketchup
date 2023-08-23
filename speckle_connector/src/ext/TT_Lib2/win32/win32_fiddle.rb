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
    module Win32FiddleImpl

      require_relative 'win32_constants.rb'
      include TT::Win32::Constants

      # Reusing the Fiddle shims used in the Win32API implementation.
      # (Yes, it's a bit of a mess.)
      require_relative '../win32_shim.rb'


      module User32

        extend Fiddle::Importer

        dlload 'User32'
        include Fiddle::Win32Types

        typealias 'LONG', 'long'
        typealias 'LPMSG', 'PVOID'

        unless Fiddle.const_defined?(:TYPE_INT16_T)
          typealias 'int16_t', 'short'
          typealias 'uint16_t', 'unsigned short'
        end

        # typedef WCHAR *LPWSTR;
        # typedef wchar_t WCHAR; // A 16-bit Unicode character.
        typealias 'LPWSTR', 'uint16_t *'

        WCHAR_T_SIZE = sizeof('uint16_t')

        # https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getactivewindow
        #
        # The return value is the handle to the active window attached to the
        # calling thread's message queue. Otherwise, the return value is NULL.
        #
        # HWND GetActiveWindow();
        extern 'HWND GetActiveWindow()'

        # https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setactivewindow
        # HWND SetActiveWindow(
        #   [in] HWND hWnd
        # );
        extern 'HWND SetActiveWindow(HWND)'

        # https://docs.microsoft.com/en-gb/windows/win32/api/winuser/nf-winuser-setwindowpos
        #
        # Changes the size, position, and Z order of a child, pop-up, or top-level
        # window. These windows are ordered according to their appearance on the
        # screen. The topmost window receives the highest rank and is the first
        # window in the Z order.
        #
        # BOOL SetWindowPos(
        #   [in]           HWND hWnd,
        #   [in, optional] HWND hWndInsertAfter,
        #   [in]           int  X,
        #   [in]           int  Y,
        #   [in]           int  cx,
        #   [in]           int  cy,
        #   [in]           UINT uFlags
        # );
        extern 'BOOL SetWindowPos(HWND, HWND, int, int, int, int, UINT)'

        # https://docs.microsoft.com/en-gb/windows/win32/api/winuser/nf-winuser-getwindowlongw
        #
        # LONG GetWindowLongW(
        #   [in] HWND hWnd,
        #   [in] int  nIndex
        # );
        extern 'BOOL GetWindowLongW(HWND, int)'

        # https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongw
        #
        # LONG SetWindowLongW(
        #   [in] HWND hWnd,
        #   [in] int  nIndex,
        #   [in] LONG dwNewLong
        # );
        extern 'LONG SetWindowLongW(HWND, int, LONG)'

        # https://docs.microsoft.com/en-gb/windows/win32/api/winuser/nf-winuser-getwindowtextw
        #
        # int GetWindowTextW(
        #   [in]  HWND   hWnd,
        #   [out] LPWSTR lpString,
        #   [in]  int    nMaxCount
        # );
        extern 'int GetWindowTextW(HWND, LPWSTR, int)'

        # https://docs.microsoft.com/en-gb/windows/win32/api/winuser/nf-winuser-getwindowtextlengthw
        #
        # int GetWindowTextLengthW(
        #  [in] HWND hWnd
        #  );
        extern 'int GetWindowTextLengthW(HWND)'

        # BOOL PeekMessageW(
        #   [out]          LPMSG lpMsg,
        #   [in, optional] HWND  hWnd,
        #   [in]           UINT  wMsgFilterMin,
        #   [in]           UINT  wMsgFilterMax,
        #   [in]           UINT  wRemoveMsg
        # );
        extern 'BOOL PeekMessageW(LPMSG, HWND, UINT, UINT, UINT)'

      end # module User32

      module Kernel32

        extend Fiddle::Importer

        dlload 'Kernel32'
        include Fiddle::Win32Types

        typealias 'LONG', 'long'

        unless Fiddle.const_defined?(:TYPE_INT16_T)
          typealias 'int16_t', 'short'
          typealias 'uint16_t', 'unsigned short'
        end

        # typedef WCHAR *LPWSTR;
        # typedef wchar_t WCHAR; // A 16-bit Unicode character.
        typealias 'LPWSTR', 'uint16_t *'
        typealias 'LPCWSTR', 'LPWSTR' # Constant string

        WCHAR_T_SIZE = sizeof('uint16_t')

        # https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-widechartomultibyte
        #
        # If successful, returns the number of bytes written to the buffer pointed
        # to by lpMultiByteStr. If the function succeeds and cbMultiByte is 0, the
        # return value is the required size, in bytes, for the buffer indicated by
        # lpMultiByteStr. Also see dwFlags for info about how the
        # WC_ERR_INVALID_CHARS flag affects the return value when invalid
        # sequences are input.
        #
        # The function returns 0 if it does not succeed.
        #
        # int WideCharToMultiByte(
        #   [in]            UINT                               CodePage,
        #   [in]            DWORD                              dwFlags,
        #   [in]            _In_NLS_string_(cchWideChar)LPCWCH lpWideCharStr,
        #   [in]            int                                cchWideChar,
        #   [out, optional] LPSTR                              lpMultiByteStr,
        #   [in]            int                                cbMultiByte,
        #   [in, optional]  LPCCH                              lpDefaultChar,
        #   [out, optional] LPBOOL                             lpUsedDefaultChar
        # );
        extern 'int WideCharToMultiByte(UINT, DWORD, PVOID, int, LPSTR, int, PVOID, PVOID)'

        # https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar
        #
        # Returns the number of characters written to the buffer indicated by
        # lpWideCharStr if successful. If the function succeeds and cchWideChar
        # is 0, the return value is the required size, in characters, for the
        # buffer indicated by lpWideCharStr. Also see dwFlags for info about how
        # the MB_ERR_INVALID_CHARS flag affects the return value when invalid
        # sequences are input.
        #
        # The function returns 0 if it does not succeed.
        #
        # int MultiByteToWideChar(
        #   [in]            UINT                              CodePage,
        #   [in]            DWORD                             dwFlags,
        #   [in]            _In_NLS_string_(cbMultiByte)LPCCH lpMultiByteStr,
        #   [in]            int                               cbMultiByte,
        #   [out, optional] LPWSTR                            lpWideCharStr,
        #   [in]            int                               cchWideChar
        # );
        extern 'int MultiByteToWideChar(UINT, DWORD, PVOID, int, LPWSTR, int)'

        # If the function succeeds, the return value is the length, in TCHARs, of
        # the string that is copied to lpszShortPath, not including the
        # terminating null character.
        #
        # If the lpszShortPath buffer is too small to contain the path, the return
        # value is the size of the buffer, in TCHARs, that is required to hold the
        # path and the terminating null character.
        #
        # If the function fails for any other reason, the return value is zero. To
        # get extended error information, call GetLastError.
        #
        # DWORD GetShortPathNameW(
        #   [in]  LPCWSTR lpszLongPath,
        #   [out] LPWSTR  lpszShortPath,
        #   [in]  DWORD   cchBuffer
        # );
        extern 'DWORD GetShortPathNameW(LPCWSTR, LPWSTR, DWORD)'

        # Sends a string to the debugger for display.
        #
        # Important  In the past, the operating system did not output Unicode
        # strings via OutputDebugStringW and instead only output ASCII strings.
        # To force OutputDebugStringW to correctly output Unicode strings,
        # debuggers are required to call WaitForDebugEventEx to opt into the new
        # behavior. On calling WaitForDebugEventEx, the operating system will know
        # that the debugger supports Unicode and is specifically opting into
        # receiving Unicode strings.
        #
        #  Remarks
        # If the application has no debugger, the system debugger displays the
        # string if the filter mask allows it. (Note that this function calls the
        # DbgPrint function to display the string. For details on how the filter
        # mask controls what the system debugger displays, see the DbgPrint
        # function in the Windows Driver Kit (WDK) on MSDN.) If the application
        # has no debugger and the system debugger is not active, OutputDebugString
        # does nothing.Prior to Windows Vista:  The system debugger does not
        # filter content.
        #
        # OutputDebugStringW converts the specified string based on the current
        # system locale information and passes it to OutputDebugStringA to be
        # displayed. As a result, some Unicode characters may not be displayed
        # correctly.
        #
        # Applications should send very minimal debug output and provide a way for
        # the user to enable or disable its use. To provide more detailed tracing,
        # see Event Tracing.
        #
        # Visual Studio has changed how it handles the display of these strings
        # throughout its revision history. Refer to the Visual Studio
        # documentation for details of how your version deals with this.
        #
        # void OutputDebugStringW(
        #   [in, optional] LPCWSTR lpOutputString
        # );
        #
        # void OutputDebugStringA(
        #   [in, optional] LPCSTR lpOutputString
        # );
        extern 'void OutputDebugStringW(LPCWSTR)'

      end # module Kernel32

      module Shell32

        extend Fiddle::Importer

        dlload 'Shell32'
        include Fiddle::Win32Types

        typealias 'LONG', 'long'
        typealias 'HRESULT', 'LONG'
        typealias 'SHFOLDERAPI', 'HRESULT'

        unless Fiddle.const_defined?(:TYPE_INT16_T)
          typealias 'int16_t', 'short'
          typealias 'uint16_t', 'unsigned short'
        end

        # typedef WCHAR *LPWSTR;
        # typedef wchar_t WCHAR; // A 16-bit Unicode character.
        typealias 'LPWSTR', 'uint16_t *'

        WCHAR_T_SIZE = sizeof('uint16_t')

        # https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetfolderpathw
        #
        # If this function succeeds, it returns S_OK. Otherwise, it returns an
        # HRESULT error code.
        #
        # SHFOLDERAPI SHGetFolderPathW(
        #   [in]  HWND   hwnd,
        #   [in]  int    csidl,
        #   [in]  HANDLE hToken,
        #   [in]  DWORD  dwFlags,
        #   [out] LPWSTR pszPath
        # );
        extern 'SHFOLDERAPI SHGetFolderPathW(HWND, int, HANDLE, DWORD, LPWSTR)'

      end # module Shell32

      class Utf16LEString

        def self.malloc(num_characters, &block)
          string = self.new(num_characters)
          block.call(string)
        ensure
          string.free
        end

        def initialize(num_characters)
          size = (num_characters + 1) * User32::WCHAR_T_SIZE
          @pointer = Fiddle::Pointer.malloc(size, Fiddle::RUBY_FREE)
        end

        def ptr
          @pointer
        end

        def free
          # Fiddle in Ruby 2.7 doesn't support #call_free.
          @pointer.call_free if @pointer.respond_to?(:call_free)
        end

        def bytesize
          @pointer.size
        end

        def size
          @pointer.size / User32::WCHAR_T_SIZE
        end

        # Returns a UTF-8 string.
        def to_s
          utf16le = @pointer.to_str
          utf16le.force_encoding(Encoding::UTF_16LE)
          utf16le.encode(Encoding::UTF_8).rstrip
        end

      end # class


      # Returns the window handle of the SketchUp window for the input queue of the
      # calling ruby method.
      #
      # @return [Integer] Returns a window handle on success or +nil+ on failure
      # @since 2.5.0
      def get_sketchup_window
        Shim.get_main_window_handle
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
        User32::SetActiveWindow(hwnd)
      end


      # @param [Integer] hwnd
      #
      # @return [String|Nil]
      # @since 2.5.0
      def get_window_text(hwnd)
        buf_len = User32::GetWindowTextLengthW(hwnd)
        return nil if buf_len == 0

        str = Utf16LEString.malloc(buf_len) do |utf16str|
          result = User32::GetWindowTextW(hwnd, utf16str.ptr, utf16str.size)
          return nil if result == 0
          utf16str.to_s
        end
        str.strip # Should have been rstrip, but ... compatibility.
      end


      # @private
      #
      # @param [Integer] csidl
      #
      # @return [String|Nil]
      # @since 2.9.0
      def get_folder_path_utf16( csidl )
        lpszLongPath = ' ' * (MAX_PATH * 2)
        lpszLongPath_ptr = Fiddle::Pointer.to_ptr(lpszLongPath)
        Shell32::SHGetFolderPathW(Fiddle::NULL, csidl, Fiddle::NULL, SHGFP_TYPE_CURRENT, lpszLongPath_ptr)
        lpszLongPath
      end


      # @private
      #
      # @param [Integer] csidl
      #
      # @return [String|Nil]
      # @since 2.9.0
      def get_short_folder_path_utf16( csidl )
        lpszLongPath = get_folder_path_utf16(csidl)
        lpszLongPath_ptr = Fiddle::Pointer.to_ptr(lpszLongPath)
        lpszShortPath_len = Kernel32::GetShortPathNameW(lpszLongPath_ptr, Fiddle::NULL, 0)

        lpszShortPath = ' ' * (lpszShortPath_len * 2)
        lpszShortPath_ptr = Fiddle::Pointer.to_ptr(lpszShortPath)
        Kernel32::GetShortPathNameW(lpszLongPath_ptr, lpszShortPath_ptr, lpszShortPath_len)
        lpszShortPath
      end


      # @param [String] utf8_string
      #
      # @return [String|Nil]
      # @since 2.9.0
      def utf8_to_utf16( utf8_string )
        utf8_null_string = "#{utf8_string}\0"

        utf8_ptr = Fiddle::Pointer.to_ptr(utf8_string)
        utf16_string_len = Kernel32::MultiByteToWideChar(CP_UTF8, 0,
                                                         utf8_ptr, utf8_string.bytesize, Fiddle::NULL, 0)

        return '' if utf16_string_len == 0

        buffer_chars = utf8_string.size + 1 # Include trailing 0
        num_bytes = buffer_chars * 2
        out_buffer = Fiddle::Pointer.malloc(num_bytes, Fiddle::RUBY_FREE)

        Kernel32::MultiByteToWideChar(CP_UTF8, 0,
                                      utf8_ptr, utf8_string.bytesize, out_buffer, buffer_chars )

        utf16le = out_buffer.to_str
        utf16le.force_encoding(Encoding::UTF_8)
        utf16le
      end


      # @private
      #
      # @param [Integer] codepage
      #
      # @return [String|Nil]
      # @since 2.9.0
      def utf16_to_codepage( utf16_string, codepage )
        utf16_ptr = Fiddle::Pointer.to_ptr(utf16_string)
        num_bytes = Kernel32::WideCharToMultiByte( codepage, 0,
                                                   utf16_ptr, -1, Fiddle::NULL, 0, Fiddle::NULL, Fiddle::NULL)

        # Need to initialize a string buffer that is UTF-8 encoded in order to get
        # identical string size behaviour as the Win32API implementation. A buffer
        # with zero bytes will cause the encoding to be ASCII-8BIT which will
        # lead to a different size being reported. This is really a bug, but for
        # the sake of paranoia in not breaking anything, exact legacy behaviour is
        # mantained.
        out_buffer_str = ' ' * num_bytes
        out_buffer = Fiddle::Pointer.to_ptr(out_buffer_str)

        Kernel32::WideCharToMultiByte(codepage, 0,
                                      utf16_ptr, -1, out_buffer, num_bytes, Fiddle::NULL, Fiddle::NULL)

        out_buffer_str.strip.strip
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
        hwnd = User32::GetActiveWindow()
        return nil if hwnd == 0

        # Verify window text as extra security to ensure it's the correct window.
        str = get_window_text(hwnd)
        return nil if str.nil?
        return nil unless str.strip == window_title.strip

        # Set frame to Toolwindow
        style = User32::GetWindowLongW(hwnd, GWL_EXSTYLE)
        return nil if style == 0

        new_style = style | WS_EX_TOOLWINDOW
        result = User32::SetWindowLongW(hwnd, GWL_EXSTYLE, new_style)
        return nil if result == 0

        # Remove and disable minimze and maximize
        # http://support.microsoft.com/kb/137033
        style = User32::GetWindowLongW(hwnd, GWL_STYLE)
        return nil if style == 0

        style = style & ~WS_MINIMIZEBOX
        style = style & ~WS_MAXIMIZEBOX
        result = User32::SetWindowLongW(hwnd, GWL_STYLE,  style)
        return nil if result == 0

        # Refresh the window frame
        # (!) SWP_NOZORDER | SWP_NOOWNERZORDER
        flags = SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE
        result = User32::SetWindowPos(hwnd, 0, 0, 0, 0, 0, flags)
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
        hwnd = User32::GetActiveWindow()
        return nil if hwnd == 0

        # Verify window text as extra security to ensure it's the correct window.
        str = get_window_text(hwnd)
        return nil if str.nil?
        return nil unless str.strip == window_title.strip

        # Remove and disable minimze and maximize
        # http://support.microsoft.com/kb/137033
        style = User32::GetWindowLongW(hwnd, GWL_STYLE)
        return nil if style == 0

        style = style & ~WS_MINIMIZEBOX
        style = style & ~WS_MAXIMIZEBOX
        result = User32::SetWindowLongW(hwnd, GWL_STYLE,  style)
        return nil if result == 0

        # Refresh the window frame
        # (!) SWP_NOZORDER | SWP_NOOWNERZORDER
        flags = SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE
        result = User32::SetWindowPos(hwnd, 0, 0, 0, 0, 0, flags)
        result != 0
      end


      # Allows the SketchUp process to process it's queued messages. Avoids whiteout.
      #
      # @return [Boolean] if message is available
      # @since 2.5.0
      def refresh_sketchup
        # If a message is available, the return value is nonzero.
        # If no messages are available, the return value is zero.
        User32::PeekMessageW(Fiddle::NULL, Fiddle::NULL, 0, 0, PM_NOREMOVE) != 0
      end


      # @param [String] string
      def debug_output(string)
        utf16_string = utf8_to_utf16(string)
        utf16_string_ptr = Fiddle::Pointer.to_ptr(utf16_string)
        Kernel32::OutputDebugStringW(utf16_string_ptr)
      end

    end

  end if TT::System.is_windows? # module TT::Win32
end

