#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'gui.rb'
require_relative 'json.rb'
require_relative 'locale.rb'
require_relative 'modal_wrapper.rb'
require_relative 'toolwindow.rb'
require_relative 'settings.rb'

# (i) Alpha stage. Very likely to be subject to change!
#
# @example
#   i = TT::GUI::Inputbox.new
#   i.add_control( {
#     :label => 'FooBar',
#     :value => 'Hello'
#   } )
#   i.prompt { |results|
#     p results
#   }
#
# @since 2.4.0
module SpeckleConnector
  class TT::GUI::Inputbox < TT::GUI::ToolWindow

    CT_LIST     = 1
    CT_RADIOBOX = 2

    # @since 2.5.5
    #attr_accessor( :controls )
    def controls; @ib_controls; end;

    # Creates a new Inputbox instance.
    #
    # @todo Escape HTML data (?) Ok on Windows IE.
    # @todo Descriptions (Info, HTML)
    # @todo Slider
    # @todo PickList
    # @todo Events
    #
    # @param [Hash] options
    # @option options [String] :title ("Inputbox")
    # @option options [String] :pref_key If present the inputbox will remember
    #   it's values and properties between sessions.
    # @option options [Boolean] :save_values (true) Set to false if you
    #   do not want the values to be remembered between sessions, but want the
    #   window size etc to be remembered. Requires +:pref_key+ to be +true+
    # @option options [Boolean] :resizable (true)
    # @option options [Integer] :width
    # @option options [Integer] :height
    # @option options [String] :accept_label ("Ok") The caption of the
    #   accept button.
    # @option options [String] :cancel_label ("Cancel") The caption of the
    #   cancel button.
    # @option options [Boolean] :modal (false) Set to true to prevent
    #   the user from interacting with the model while the window is open. It also
    #   prevents other modal windows (From TT_Lib) from opening.
    # @option options [Boolean] :true_modal (false) *Deprecated* Under
    #   Windows the window can be made into a true modal window, but since it
    #   can't under OSX this key is deprecated.
    #
    # @since 2.4.0
    def initialize(options={})
      raise ArgumentError unless options.is_a?( Hash )

      # Window options (Sent to Window < Webdialog instance)
      wnd_options = {
        :dialog_title => 'Inputbox',
        :scrollable   => false,
        :resizable    => true
      }
      wnd_options[:dialog_title]    = options[:title]     if options.key?(:title)
      wnd_options[:preferences_key] = options[:pref_key]  if options.key?(:pref_key)
      wnd_options[:resizable]       = options[:resizable] if options.key?(:resizable)
      wnd_options[:width]           = options[:width]     if options.key?(:width)
      wnd_options[:height]          = options[:height]    if options.key?(:height)
      wnd_options[:left]            = options[:left]      if options.key?(:left)
      wnd_options[:top]             = options[:top]       if options.key?(:top)
      wnd_options[:min_width] = 200
      wnd_options[:min_height] = 12
      # Window UI options (Sent to Javascript)
      @html_options = {
        :accept_label => 'Ok',
        :cancel_label => 'Cancel'
      }
      @html_options[:save_values]  = options[:save_values] if options.key?(:save_values)
      @html_options.merge!(options)
      # Internal flags.
      @save_values  = ( options.key?(:save_values) )  ? options[:save_values] : true
      @true_modal   = ( options.key?(:true_modal) )   ? options[:true_modal]  : false
      @modal        = ( options.key?(:modal) )        ? options[:modal]       : false
      # Array of the controls and their values.
      @ib_controls = []
      @values = nil
      # Flag indicating if the window is closing.
      @closing = false
      # Initate the ModalWrapper
      if !@true_modal && @modal
        @modal_window = TT::GUI::ModalWrapper.new( self )
      end
      # Control's label is the section key for settings
      if options.key?(:pref_key) && @save_values
        @defaults = TT::Settings.new( options[:pref_key] )
      else
        @defaults = nil
      end

      # Initialize the parent Window class
      super( wnd_options )
      # Using relative paths, relying on the BASE element seem to fail on some
      # computers running various versions of Windows. Not sure why - maybe
      # different security settings..?
      wpath = File.join( TT::Lib.path, 'webdialog' )
      add_script( local_path( File.join(wpath, 'js', 'inputbox.js') ) )
      add_style( local_path( File.join(wpath, 'css', 'inputbox.css') ) )

      add_action_callback( 'Inputbox_ready',  &method(:event_inputbox_ready) )
      add_action_callback( 'Inputbox_accept', &method(:event_inputbox_accept) )
      add_action_callback( 'Inputbox_cancel', &method(:event_inputbox_cancel) )

      set_on_close( &method(:event_inputbox_close) )
    end


    # When the webdialog reports it's ready, call function to start building the
    # UI with the given user options.
    def event_inputbox_ready( window, params )
      TT.debug '>> Input Ready'
      # Window settings
      o = TT::JSON.new( @html_options )
      window.execute_script("inputbox.init_html(#{o});")
      # Add controls
      @ib_controls.each { |control|
        c = control.clone
        if c[:value].is_a?( Float ) && !c[:value].is_a?( Length )
          c[:value] = TT::Locale.float_to_string( c[:value] )
        elsif c[:value].is_a?( Length )
          c[:value] = c[:value].to_s
        end
        window.execute_script("inputbox.add_control(#{c});")
      }
    end


    # When the user accepts the values in the Inputbox, collect the data and
    # convert them back from string into their input types.
    # (!) Build Hash with keys and values.
    def event_inputbox_accept( window, params )
      TT.debug '>> Input Accept'
      @values = {}
      @ib_controls.each { |control|
        value = window.send( :get_value, control[:id] )
        type = ( control[:options] && control[:multiple] ) ? Array : control[:value]
        value = TT::Locale.cast_string(value, type, '||')
        @defaults[ control[:label] ] = value if @save_values
        @values[ control[:key] ] = value
        control[:value] = value
      }
      window.close
    end


    # User cancels the inputbox, either by using the Cancel button, the Close
    # button or the Right-Click menu.
    def event_inputbox_cancel( window, params )
      TT.debug '>> Input Cancel'
      window.close
    end


    # Flag the window as closing to avoid the Modal_Wrapper from also calling
    # close - something which will lead to multiple triggering of this event.
    def event_inputbox_close
      TT.debug '>> Window Closed'
      @closing = true
      @modal_window.close if @modal_window
      begin
        @block.call(@values) # (?) Delay with timer to ensure window closes?
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
        UI.messagebox("#{e.message}\n\n#{e.backtrace.join("\n")}", MB_MULTILINE)
      end
    end


    # Flag indicating if the webdialog is closing.
    #
    # @since 2.4.0
    def closing?
      @closing
    end


    # Adds a new input control.
    #
    # @example Normal Textbox
    #  i = TT::GUI::Inputbox.new( options )
    #  i.add_control( {
    #    :label => 'Hello',
    #    :value => 'World'
    #  } )
    #
    # @example Natrually Ordered Multi Select List
    #  i = TT::GUI::Inputbox.new( options )
    #  i.add_control( {
    #    :label         => 'My List',
    #    :description   => 'Lorem Ipsum Dolor Sit Amet.',
    #    :value         => ['Hello', 'World'],
    #    :options       => ['Foo', 'Hello', 'Bar', 'World', 'FooBar'],
    #    :multiple      => true,
    #    :order         => 1,
    #    :natrual_order => true,
    #    :size          => 5
    #  } )
    #
    # @param [Hash] options
    # @option options [String] :label *Required* Should be unique in order for
    #   persistant values to function.
    # @option options [String|Array] :value *Required* Default value.
    # @option options [Symbol] :key Identifying key used in the result hash when
    #   the dialog closes. This was introdused in 2.5.0. Before that the results
    #   where Arrays.
    # @option options [String] :description Explainatory text accosiated to the
    #   control.
    # @option options [Array] :options Array of valued, used for lists and
    #   radiobox options.
    # @option options [Integer] :order -1, 0 or 1 - -1 means decending order, 0 no
    #   order, 1 accending order.
    # @option options [Boolean] :natrual_order If the list is ordered, set this
    #   +true+ for a natrual ordering.
    # @option options [Integer] :size Set this property for a scrollable list
    #   instead of a drop down list.
    # @option options [Boolean] :multiple Allows mulitple items to be selected.
    # @option options [Integer] :type Possible constants:
    #   * +TT::GUI::Inputbox::CT_LIST+
    #   * +TT::GUI::Inputbox::CT_RADIOBOX+
    # @option options [Boolean] :no_save Prevents the value from being saved if
    #   set to +true+. Added version 2.5.0.
    #
    # @since 2.4.0
    def add_control(options)
      options = ( options.is_a?( Hash ) ) ? TT::JSON.new( options ) : options.dup
      raise ArgumentError unless options.is_a?( TT::JSON )
      # Process and prepare the options before sending it to the Webdialog.
      options[:id] = "Inputbox_control#{@ib_controls.size}"
      # Ensure the options are JSON object which can be sent to the Webdialog.
      # Hashes will aumatically be converted to JSON objects.
      if options.key?( :key )
        # Ensure key is unique.
        key = options[:key]
        @ib_controls.each { |control|
          raise ArgumentError, 'options[:key] must be uniqe' if control[:key] == key
        }
      else
        options[:key] = options[:id]
      end
      # Default value.
      if @defaults && !options[:no_save]
        options[:value] = @defaults[ options[:label], options[:value] ]
      end
      @ib_controls << options
      # If controls are added while the inputbox is open it needs to be notified.
      if self.visible?
        self.execute_script("inputbox.add_control(#{options});")
      end
    end


    # *Note* As of 2.5.0 the returned argument of the block is a Hash instead of
    # an Array.
    #
    # @param [&block] block the callback that receives the resulting values as a
    # +Hash+ when the inputbox closes. Only used if the inputbox is not true modal.
    #
    # @return [Hash|nil] Hash of resulting values if Inputbox is true modal, nil otherwise.
    # @since 2.4.0
    def prompt(&block)
      @values = nil
      @block = block
      if @true_modal
        show_window(@true_modal)
        @values
      elsif @modal
        @modal_window.show
        nil
      else
        self.show_window
        nil
      end
    end


    private


    # Returns the value of the given element identified by its index in +@controls+.
    #
    # @param [String] id
    #
    # @return [String]
    # @since 2.4.0
    def get_value(id)
      self.execute_script("inputbox.get_value('#{id}');")
      self.get_element_value('RUBY_Inputbox_get_value');
    end

  end # module TT::GUI::Inputbox
end
