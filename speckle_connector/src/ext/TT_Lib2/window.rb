#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'gui.rb'
require_relative 'javascript.rb'
require_relative 'system.rb'
require_relative 'webdialog_patch.rb'

module SpeckleConnector
  # @note Alpha stage. Very likely to be subject to change!
  #
  # @example
  #   w = TT::GUI::Window.new
  #   w.show_window
  #
  # @since 2.4.0
  class TT::GUI::Window < TT::WebDialogPatch

    THEME_DEFAULT   = 'window.html'.freeze
    THEME_GRAPHITE  = 'window_graphite.html'.freeze

    # Callback Events

    # Called when the HTML DOM is ready.
    #
    # @since 2.4.0
    EVENT_WINDOW_READY = proc { |window, params|
      TT.debug( '>> Dialog Ready' )
      window.add_controls_to_webdialog()
      window.trigger_DOM_ready() # 2.7.0
    }.freeze

    # Called when a control triggers an event.
    # params possibilities:
    #   "<ui_id>||<event>"
    #   "<ui_id>||<event>||arg1,arg2,arg3"
    #
    # @since 2.5.0
    EVENT_CALLBACK = proc { |window, params|
      TT.debug( '>> Event Callback' )
      TT.debug( params )
      begin
        ui_id, event_str, args_str = params.split('||')
        event = event_str.intern
        # Catch Debug Console callbacks
        return TT.debug( args_str ) if ui_id == 'Console'
        # Process Control
        control = window.get_control_by_ui_id(ui_id)
        if control
          if args_str
            args = args_str.split(',')
            control.call_event( event, args )
          else
            control.call_event( event )
          end
        end
      ensure
        # Pump next message.
        window.call_script( 'Bridge.pump_message' )
      end
    }.freeze

    # Called when a URL link is clicked.
    #
    # @since 2.7.0
    EVENT_OPEN_URL = proc { |window, params|
      TT.debug( '>> Open URL' )
      UI.openURL( params )
    }.freeze

    include TT::GUI::ContainerElement

    # @since 2.6.0
    attr_accessor( :theme )
    # @since 2.4.0
    attr_accessor( :parent, :window ) # (?) Move to ContainerElement?

    # In addition to the hash keys supported by WebDialog.new, there are additional
    # keys availible:
    # * +:title+ alias for :dialog_title
    # * +:pref_key+ alias for :preferences_key
    #
    # @note This method is currently not compatible with SketchUp 6 and older.
    #
    # @overload initialize(title, scrollable, pref_key, width, height, left, top, resizable)
    #   @param [optional, String] title
    #   @param [optional, Boolean] scrollable
    #   @param [optional, String] pref_key
    #   @param [optional, Integer] width
    #   @param [optional, Integer] height
    #   @param [optional, Integer] left
    #   @param [optional, Integer] top
    #   @param [optional, Boolean] resizable
    #
    # @overload initialize(hash)
    #   @param [optional, Hash] hash
    #   @option hash [String] :dialog_title
    #   @option hash [Boolean] :scrollable
    #   @option hash [String] :preferences_key
    #   @option hash [Integer] :width
    #   @option hash [Integer] :height
    #   @option hash [Integer] :left
    #   @option hash [Integer] :top
    #   @option hash [Boolean] :resizable
    #   @option hash [Boolean] :min_width
    #   @option hash [Boolean] :min_height
    #   @option hash [Boolean] :max_width
    #   @option hash [Boolean] :max_height
    #   @option hash [Boolean] :mac_only_use_nswindow
    #
    # @since 2.4.0
    def initialize(*args)
      # WebDialog.new arguments:
      #
      # title, scrollable, pref_key, width, height, left, top, resizable
      #   0         1          2       3       4      5    6       7
      #
      #
      # WebDialog.new hash keys:
      #
      # :dialog_title
      # :scrollable
      # :preferences_key
      # :width
      # :height
      # :left
      # :top
      # :resizable
      # :mac_only_use_nswindow

      @theme = THEME_DEFAULT

      @window = self # Required by ContainerElement

      @event_DOM_ready = nil

      # Default properties
      # (!) Add theme
      @props = {
        :title      => 'Untitled Window',
        :scripts    => [],
        :styles     => [],
        :scrollable => false,
        :resizable  => true,
        :left       => 250,
        :top        => 350,
        :width      => 200,
        :height     => 300
      }

      # Process the arguments.
      if args.length == 1 && args[0].is_a?(Hash)
        # Hash arguments
        options = args[0]
        # Syncronize aliased keys. (i) Getting messy. Avoid this.
        options[:dialog_title]    = options[:title] if options.key?(:title)
        options[:title]           = options[:dialog_title] if options.key?(:dialog_title)
        options[:preferences_key] = options[:pref_key] if options.key?(:pref_key)
        options[:pref_key]        = options[:preferences_key] if options.key?(:preferences_key)
        [
          :title, :dialog_title,
          :pref_key, :preferences_key,
          :resizable,
          :scrollable,
          :width,
          :height,
          :left,
          :top
        ].each { |key|
          @props[key] = options[key] if options.key?( key )
        }
      else
        # Classic arguments.
        [
          :title,           # 0
          :scrollable,      # 1
          :preferences_key, # 2
          :width,           # 3
          :height,          # 4
          :left,            # 5
          :top,             # 6
          :resizable        # 7
        ].each_with_index { |key, index|
          break unless args.length > index
          next if args[index].nil?
          @props[key] = args[index] #if args.length > index
        }
      end

      # Alias keys.
      @props[:dialog_title]     = @props[:title] if @props.key?(:title)
      @props[:preferences_key]  = @props[:pref_key] if @props.key?(:pref_key)

      # Init the real WebDialog
      #
      # (!) It appears that when using a hash to init the webdialog and one
      # supplies a preference key to store it's position and size only the
      # registry section is created, but the size and position is not stored.
      # Windows - SU8M1, SU7.1
      #
      # (!) UPDATE: Preferences work if one destroy the WebDialog instance and
      # create a new one before using Webdialog.show.
      #
      # (!) In versions earlier than SU8(M1?), any nil in arguments would stop
      # the processing of the remaining arguments.
      #
      # (!) If left and Top is not spesified the WebDialog will appear in the
      # upper left corner of the screen.
      #
      # In order to work around all these issues it's best to not use a hash,
      # but instead use all arguments with decent default values.
      if @props.key?( :preferences_key )
        # When preferences are saved, used classic arguments as they are not
        # saved when using a hash. ( SU8.0M1, SU7.1 )
        title       = @props[:dialog_title]
        scrollable  = @props[:scrollable]
        pref_key    = @props[:preferences_key]
        width       = @props[:width]
        height      = @props[:height]
        left        = @props[:left]
        top         = @props[:top]
        resizable   = @props[:resizable]
        super( title, scrollable, pref_key, width, height, left, top, resizable )
        min_width  = @props[:min_width]  if @props.key?( :min_width )
        min_height = @props[:min_height] if @props.key?( :min_height )
        max_width  = @props[:max_width]  if @props.key?( :max_width )
        max_height = @props[:max_height] if @props.key?( :max_height )
      else
        # When preferences are not saved, use a hash because in SU prior to
        # SU8.0M1 processing of arguments would stop after a nil. So if one
        # wants to skip the preference argument one need to use the hash.
        # (!) Not compatible with SU6.
        super( @props )
      end

      # (!) Remember window positions. SU only remembers them between each session.

      # Ensure the size for fixed windows is set - and not read from the last state.
      if @props.key?(:width) && @props.key?(:height) && !@props[:resizable]
        set_size(@props[:width], @props[:height])
      end

      # Turn of the navigation buttons by default.
      if respond_to?( :navigation_buttons_enabled )
        navigation_buttons_enabled = false
      end

      # Set HTML file with the core HTML, CSS and JS required.
      # (?) Is this not redundant since self.set_html is used in .show_window?
      # As noted in The Lost Manual, onload will trigger under OSX when .set_file
      # or .set_html is used.
      #self.set_file(TT::Lib::path + '/webdialog/window.html')

      # (i) If procs are created in the initalize method for #add_action_callback
      #     then the WebDialog instance will not GC.

      add_action_callback( 'Window_Ready', &EVENT_WINDOW_READY )
      add_action_callback( 'Event_Callback', &EVENT_CALLBACK )
      add_action_callback( 'Open_URL', &EVENT_OPEN_URL )

    end # def initialize


    # @return [String]
    # @since 2.6.0
    def title
      @props[:title].dup
    end


    # @note All local paths should be processed with {#local_path} to ensure
    #   compatibility between platforms.
    #
    # @param [String] file
    #
    # @return [String]
    # @since 2.4.0
    def add_script( file )
      @props[:scripts] << file
      file
    end

    # @note All local paths should be processed with {#local_path} to ensure
    #   compatibility between platforms.
    #
    # @param [String] file
    #
    # @return [String]
    # @since 2.4.0
    def add_style( file )
      @props[:styles] << file
      file
    end

    # Internal method.
    #
    # @private
    #
    # @param [Control] control
    #
    # @return [Nil]
    # @since 2.5.0
    def add_control_to_webdialog( control )
      props = control.properties()
      execute_script( "UI.add_control(#{props})" )
      nil
    end
    #private :add_control_to_webdialog

    # @param [String] ui_id ID to a +Control.ui_id+
    #
    # @return [String] Returns the checked state for the given jQuery selector.
    # @since 2.7.0
    def get_checkbox_state( ui_id )
      call_script( 'Webdialog.get_checkbox_state', ui_id )
    end

    # @param [String] selector jQuery selector
    #
    # @return [String] Returns the checked state for the given jQuery selector.
    # @since 2.7.0
    def get_checked_state( selector )
      call_script( 'Webdialog.get_checked_state', selector )
    end

    # @param [String] selector jQuery selector
    #
    # @return [String] Returns the text content for the given jQuery selector.
    # @since 2.5.0
    def get_text(selector)
      call_script( 'Webdialog.get_text', selector )
    end

    # @param [String] selector jQuery selector
    #
    # @return [String] Returns the HTML code for the given jQuery selector.
    # @since 2.5.0
    def get_html(selector)
      call_script( 'Webdialog.get_html', selector )
    end

    # It appear that under OSX UI::WebDialog.get_element_value doesn't work for
    # <TEXTAREA> and <SELECT> elements. Using this instead solves the issue.
    #
    # @param [String] selector jQuery selector
    #
    # @return [String] Returns the value for the given jQuery selector.
    # @since 2.5.0
    def get_value(selector)
      call_script( 'Webdialog.get_value', selector )
    end

    # @param [String] ui_id Control.ui_id
    #
    # @return [String] Returns the value for the given Control.
    # @since 2.5.0
    def get_control_value( ui_id )
      call_script( 'Webdialog.get_value', "##{ui_id}" )
    end

    # Returns an array with the width and height of the client area.
    #
    # @return [Array<Integer,Integer>]
    # @since 2.5.0
    def get_client_size
      call_script( 'Webdialog.get_client_size' )
    end

    # Event callback for when the HTML DOM is ready.
    #
    # @yield [window] Return the window object where the DOM is ready.
    #
    # @since 2.7.0
    def on_ready( &block )
      # (?) Allow more than one event handler?
      @event_DOM_ready = block
    end

    # Triggers the DOM ready event.
    #
    # @private
    #
    # @since 2.7.0
    def trigger_DOM_ready
      @event_DOM_ready.call( self ) if @event_DOM_ready
    end

    # Adjusts the window so the client area fits the given +width+ and +height+.
    #
    # @param [Integer] width
    # @param [Integer] height
    #
    # @return [Boolean] Returns false if the size can't be set.
    # @since 2.5.0
    def set_client_size(width, height)
      unless visible?
        # (?) Queue up size for when dialog opens.
        return false
      end
      # (!) Cache size difference.
      set_size( width, height )
      client_width, client_height = get_client_size()
      adjust_width  = width  - client_width
      adjust_height = height - client_height
      unless adjust_width == 0 && adjust_height == 0
        new_width  = width  + adjust_width
        new_height = height + adjust_height
        set_size( new_width, new_height )
      end
      true
    end

    # Wrapper to build a script string and return the return value of the called
    # Javascript.
    #
    # This method also ensures a that the +<SCRIPT>+ elements which
    # +UI::WebDialog.execute_script+ leaves behind is cleaned up.
    #
    #  return_value = window.call_script('alert', 'Hello World')
    #
    # @param [String] function Name of JavaScript function to call.
    #
    # @return [Mixed]
    # @since 2.5.0
    def call_script(function, *args)
      # Ensure that we don't pull old data back from the WebDialog if it should fail.
      execute_script( 'Bridge.reset()' )
      # (!) SU-0415
      # Reports of .execute_script might have a hard limit - possibly under OSX only.
      # Windows does seem unaffected.
      # Test case:
      #  w.execute_script("alert('#{'x'*10000000}'.length);")
      arguments = args.map { |arg| TT::Javascript.to_js(arg) }.join(',')
      javascript = "#{function}(#{arguments});".inspect
      # If WebDialog is not visible, or no HTML is populated (lacking DOM) then
      # .execute_script returns false.
      #
      # (i) OSX - SU6
      # http://forums.sketchucation.com/viewtopic.php?f=180&t=8316#p49259
      # Indicates that ; might cause the call to fail. Seems to work without,
      # so keeping it like that to be on the safe size.
      # puts "Bridge.execute(#{javascript})" #DEBUG
      if not execute_script( "Bridge.execute(#{javascript})" )
        raise "Script could not be executed. Was window visible? (#{visible?})"
      end
      # (?) Catch JavaScript errors? Or just let the WebDialog display the error?
      raw_data = get_element_value('RUBY_bridge');
      # The JS Bridge converts the JS values into Ruby code strings.
      # (?) Catch exceptions? Re-raise with custom exception?
      eval( raw_data )
    end

    # Open or bring to front the window.
    #
    # @todo Add black callback for ready/load event.
    #
    # @param [Boolean] modal Deprecated argument. Doesn't work across platforms.
    #
    # @return [Nil]
    # @since 2.4.0
    def show_window( modal = false )
      if visible?
        bring_to_front()
      else
        # Under Windows, the HTML is populated when the window is shown.
        # Under OSX, the HTML is populated when set_html is called.
        # This can be seen by attaching a callback to the DOM load event in JS.
        #
        # We use set_html here to prevent Macs loading the whole dialog when the
        # plugin loads. No need to populate the dialog and use extra resources
        # if it will never be used.
        set_html( build_html )

        # (!) Use the ModalWrapper for model windows.
        if TT::System.is_osx? || modal
          show_modal()
          if !@props[:resizable] && TT::System.is_windows?
            TT::Win32.window_no_resize( @props[:title] )
          end
        else
          show()
          if !@props[:resizable]
            TT::Win32.window_no_resize( @props[:title] )
          end
        end
      end
      nil
    end
    private :show, :show_modal


    # Local paths must be prefixed with file:/// under OSX for set_html to work.
    # It probably is the correct way to do so anyway.
    #
    # @param [String] path
    #
    # @return [String]
    # @since 2.5.1
    def local_path( path )
      expanded_path = File.expand_path( path )
      match = expanded_path.match(/^(\/*)/)
      size = (match) ? match[1].size : 0
      prefix = '/' * (3 - size)
      "file:#{prefix}#{expanded_path}"
    end

    # @since 2.6.0
    def inspect
      %&<#{self.class}:#{TT.object_id_hex(self)} "#{@props[:title]}">&
    end


    private

    # @return [String]
    # @since 2.6.0
    def get_theme_path
      path = TT::Lib::path + "/webdialog/#{@theme}"
      unless File.exist?( path )
        path = TT::Lib::path + "/webdialog/#{THEME_DEFAULT}"
        puts "Warning! Theme '#{@theme}' could not be loaded. File not found."
      end
      unless File.exist?( path )
        raise "Could not load TT::Window theme: '#{@theme}' - #{path}"
      end
      path
    end

    # @return [String]
    # @since 2.4.0
    def build_html
      html = ''
      # HTML base URI path
      path = local_path( File.join(TT::Lib::path, 'webdialog') )
      path = "#{path}/" # URI need trailing slash.
      # Load theme template
      filemode = 'r'
      if RUBY_VERSION.to_f > 1.8
        filemode << ':UTF-8'
      end
      File.open( get_theme_path() , filemode) { |file|
        html = file.read
      }
      # Insert CSS property to hide scrollbars if they are disabled.
      styles = @props[:styles].map { |f|
        "<link rel='stylesheet' type='text/css' media='screen' href='#{f}' />"
      }
      unless @props[:scrollable]
        styles << '<style type="text/css">html{overflow:hidden;}</style>'
      end
      # Compile strings
      styles  = styles.join("\n\t")
      scripts = @props[:scripts].map { |f|
        "<script type='text/javascript' src='#{f}'></script>"
      }.join("\n\t")
      # Insert variables
      html.gsub!( '%TITLE%', @props[:title] )
      html.gsub!( '%PATH%', path )
      html.gsub!( '%STYLES%', styles )
      html.gsub!( '%SCRIPTS%', scripts )
      content = ''
      html.gsub!( '%CONTENT%', content )
      return html
    end

  end # module TT::GUI::Window
end
