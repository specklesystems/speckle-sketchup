#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative '../../TT_Lib2.rb'
require_relative '../system.rb'

module SpeckleConnector
  module TT::Win32
    # @since 2.13.0
    module Constants

      # C/C++ constants.
      NULL = 0

      # Windows constants.
      MAX_PATH = 260

      # Code Page Identifiers
      # http://msdn.microsoft.com/en-us/library/windows/desktop/dd317756%28v=vs.85%29.aspx
      CP_ACP = 0
      CP_UTF8 = 65001

      # SHGetFolderPath constants.
      SHGFP_TYPE_CURRENT = 0
      SHGFP_TYPE_DEFAULT = 1

      # CSIDL
      # http://msdn.microsoft.com/en-us/library/bb762494%28v=vs.85%29.aspx
      CSIDL_LOCAL_APPDATA = 0x001c

      # Window Styles
      # http://msdn.microsoft.com/en-us/library/czada357.aspx
      # http://msdn.microsoft.com/en-us/library/ms632680%28VS.85%29.aspx
      # http://msdn.microsoft.com/en-us/library/ms632600%28v=vs.85%29.aspx
      WS_CAPTION      = 0x00C00000
      WS_SYSMENU      = 0x00080000
      WS_MAXIMIZEBOX  = 0x10000
      WS_MINIMIZEBOX  = 0x20000
      WS_SIZEBOX      = 0x40000
      WS_POPUP        = 0x80000000

      WS_EX_TOOLWINDOW = 0x00000080
      WS_EX_NOACTIVATE = 0x08000000

      # GetWindowLong() flags
      # http://msdn.microsoft.com/en-us/library/ms633584%28v=vs.85%29.aspx
      GWL_STYLE   = -16
      GWL_EXSTYLE = -20

      # SetWindowPos() flags
      # http://msdn.microsoft.com/en-us/library/ms633545%28v=vs.85%29.aspx
      SWP_NOSIZE       = 0x0001
      SWP_NOMOVE       = 0x0002
      SWP_NOACTIVATE   = 0x0010
      SWP_DRAWFRAME    = 0x0020
      SWP_FRAMECHANGED = 0x0020
      SWP_NOREPOSITION = 0x0200

      HWND_BOTTOM     =  1
      HWND_TOP        =  0
      HWND_TOPMOST    = -1
      HWND_NOTOPMOST  = -2

      # GetWindow() flags
      # http://msdn.microsoft.com/en-us/library/ms633515%28v=vs.85%29.aspx
      #GW_HWNDFIRST    = 0
      #GW_HWNDLAST     = 1
      #GW_HWNDNEXT     = 2
      #GW_HWNDPREV     = 3
      #GW_OWNER        = 4
      #GW_CHILD        = 5
      #GW_ENABLEDPOPUP = 6

      # GetAncestor() flags
      # http://msdn.microsoft.com/en-us/library/ms633502%28v=vs.85%29.aspx
      GA_PARENT     = 1
      GA_ROOT       = 2
      GA_ROOTOWNER  = 3

      # PeekMessage() flags
      PM_NOREMOVE = 0x0000 # Messages are not removed from the queue after processing by PeekMessage.
      PM_REMOVE   = 0x0001 # Messages are removed from the queue after processing by PeekMessage.
      PM_NOYIELD  = 0x0002 # Prevents the system from releasing any thread that is waiting for the caller to go idle (see WaitForInputIdle).

    end
  end if TT::System.is_windows? # module TT::Win32
end

