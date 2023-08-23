#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'boolean_attributes.rb'

module SpeckleConnector
  # @example Profile Definition
  #
  #   TT::Profiler.new( 'Editor Activation' ) {
  #     self.report_each_event = true
  #     self.report_event_start = true
  #     track( TT_Vertex, :edit_vertex )
  #     track( TT_Vertex::Editor, :activate )
  #     track( TT_Vertex::Editor, :build_ui )
  #     track( TT_Vertex::Selection )
  #     start()
  #   }
  #
  # @since 2.7.0
  class TT::Profiler

    extend TT::BooleanAttributes

    battr_reader :active
    battr_accessor :report_each_event, :report_event_start

    attr_reader :data
    attr_reader :triggers

    battr_accessor :debug

    # @since 2.7.0
    def initialize( title = '', &block )
      @title = title

      @triggers = {}
      @tracker = {}
      @data = {}

      @active = false

      @report_each_event = true
      @report_event_start = true

      @debug = false

      instance_eval( &block ) if block_given?
    end

    # @return [String]
    # @since 2.7.0
    def inspect
      hex_id = TT.object_id_hex( self )
      post_fix = ( @title.empty? ) ? '' : %{ - "#{@title}"}
      return "#<#{self.class.name}:#{hex_id}#{post_fix}>"
    end

    # (!) http://blog.grayproductions.net/articles/caching_and_memoization

    # @param [Class,Module] klass
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 2.7.0
    def track( klass, method_id = nil )
      if method_id
        track_method( klass, method_id )
      else
        for method_id in all_methods( klass )
          track_method( klass, method_id )
        end
      end
      nil
    end

    # @param [Class,Module] klass
    #
    # @return [Array]
    # @since 2.7.0
    def all_methods( klass )
      stack = []
      stack.concat( klass.methods(false) )
      stack.concat( klass.instance_methods(false) )
      stack.concat( klass.protected_methods(false) )
      stack.concat( klass.protected_instance_methods(false) )
      stack.concat( klass.private_methods(false) )
      stack.concat( klass.private_instance_methods(false) )
      stack.map! { |method_name| method_name.to_sym }
      stack
    end

    # @param [Class,Module] klass
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 2.7.0
    def track_method( klass, method_id )
      @triggers[ klass ] ||= {}
      @triggers[ klass ][ method_id ] = []
      @tracker[ klass ] ||= []
      @tracker[ klass ] << method_id
      @data[ klass ] ||= {}
      @data[ klass ][ method_id ] = {
        :calls => 0,
        :real_time => 0.0
      }
      if active?
        profile_method( klass, method_id )
      end
      nil
    end

    # @param [Class,Module] klass
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 2.7.0
    def untrack( klass, method_id = nil )
      if method_id
        self.untrack_method( klass, method_id )
      else
        for method_id in all_methods( klass )
          self.untrack_method( klass, method_id )
        end
      end
      nil
    end

    # @param [Class,Module] klass
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 2.7.0
    def untrack_method( klass, method_id )
      original = get_profile_method_id( method_id )
      remove_wrapper = proc {
        if method_defined?( method_id ) && method_defined?( original )
          remove_method( method_id )
          alias_method( method_id, original )
          remove_method( original )
        end
      }
      # Instance Methods
      klass.class_eval( &remove_wrapper )
      # Class Methods
      metaklass = ( class << klass; self; end )
      metaklass.class_eval( &remove_wrapper )
      # Clean up references
      @tracker[ klass ].delete( method_id )
      @tracker.delete( klass ) if @tracker[ klass ].empty?
      nil
    end

    # @return [Nil]
    # @since 2.7.0
    def start
      @active = true
      for klass, methods in @tracker
        for method_id in methods
          profile_method( klass, method_id )
        end
      end
      nil
    end

    # @return [Nil]
    # @since 2.7.0
    def stop
      for klass, methods in @tracker
        for method_id in methods
          untrack_method( klass, method_id )
        end
      end
      @active = false
      nil
    end

    # @return [Nil]
    # @since 2.7.0
    def reset
      for klass, methods in @data
        for method_id, log_data in methods
          @data[ klass ][ method_id ] = {
            :calls => 0,
            :real_time => 0.0
          }
        end
      end
      nil
    end

    # @return [Proc]
    # @since 2.7.0
    def attach_trigger( klass, method_id, &block )
      @triggers[ klass ] ||= {}
      @triggers[ klass ][ method_id ] ||= []
      @triggers[ klass ][ method_id ] << block
      block
    end

    # @return [Mixed]
    # @since 2.7.0
    def detach_trigger( klass, method_id, proc )
      return false unless @triggers[ klass ]
      return false unless @triggers[ klass ][ method_id ]
      @triggers[ klass ][ method_id ].delete( proc )
    end

    # @return [Nil]
    # @since 2.7.0
    def print_report( output = $stdout )
      timestamp = Time.now.strftime('%d %B %Y - %H:%M')
      report = ''
      report << "\n\n"
      report << "==============================================================\n"
      report << " Profile: #{@title} (#{timestamp})\n"
      report << "--------+----------+------------+----------+------------------\n"
      report << "   %%   |          | cumulative | average  | Method\n"
      report << "  time  |  calls   |  seconds   | seconds  | Name\n"
      report << "--------+----------+------------+----------+------------------\n"
      # Sum up grand totals.
      total_real_time = 0.0
      total_calls = 0
      for klass, methods in @data
        for method_id, log_data in methods
          total_calls += log_data[ :calls ]
          total_real_time += log_data[ :real_time ]
        end
      end
      total_average = ( total_calls == 0 ) ? 0.0 : total_real_time / total_calls
      # Process each call.
      for klass, methods in @data
        for method_id, log_data in methods
          method_name = "#{klass.name}.#{method_id}"
          calls = log_data[ :calls ]
          total = log_data[ :real_time ]
          percent = ( total / total_real_time ) * 100
          average = ( calls == 0 ) ? 0.0 : total / calls
          report << sprintf(
            " %6.2f | %8d |  %8.4f  | %8.4f | %s\n",
            percent, calls, total, average, method_name
          )
        end
      end
      report << "--------+----------+------------+----------+------------------\n"
      report << sprintf(
        " %6.2f | %8d |  %8.4f  | %8.4f | %s\n",
        100.0, total_calls, total_real_time, total_average, 'Total'
      )
      report << "========+==========+============+==========+==================\n"
      report << "\n\n"
      output.write( report )
      nil
    end

    private

    # @param [Symbol] method_id
    #
    # @return [Symbol]
    # @since 2.7.0
    def get_profile_method_id( method_id )
      "profile_#{method_id}".to_sym
    end

    # @param [Class,Module] klass
    # @param [Symbol] method_id
    #
    # @return [Nil]
    # @since 2.7.0
    def profile_method( klass, method_id )
      puts "> Profile Method: #{klass}.#{method_id}" if debug?
      # Alias the original method and wrap it in a performance tracking block.
      original = get_profile_method_id( method_id )
      profiler = self
      method_wrapper = proc {
        # Remove old profiler.
        if method_defined?( original ) || private_method_defined?( method_id )
          profiler.untrack_method( klass, method_id )
        end
        # Attach new profiler.
        if method_defined?( method_id ) || private_method_defined?( method_id )
          puts "  > Defined (#{self})" if profiler.debug?
          alias_method( original, method_id )
          define_method( method_id ) { |*args|
            call_id = Time.now.hash.abs + rand.hash.abs
            method_name = "#{klass}.#{method_id}"
            # Output live data - start of call.
            if profiler.report_event_start? && profiler.report_each_event?
              puts "> ##{call_id} #{method_name} : [Begin]"
            end
            # Time Event
            #
            # Real, User and Sys process time statistics:
            # http://stackoverflow.com/a/556411/486990
            real = Time.now
            result = send( original, *args )
            real_lapsed = Time.new - real
            # Log data.
            profiler.data[ klass ][ method_id ][ :calls ] += 1
            profiler.data[ klass ][ method_id ][ :real_time ] += real_lapsed
            # Output live data - end of call.
            real_formatted = sprintf( '%.4f', real_lapsed )
            if profiler.report_each_event?
              puts sprintf( '> #%d %s : %.4fs', call_id, method_name, real_lapsed )
            end
            # Trigger events.
            procs = profiler.triggers
            if procs[ klass ] && procs[ klass ][ method_id ]
              for proc in procs[ klass ][ method_id ]
                proc.call( profiler )
              end
            end
            result
          }
        else
          puts "  > Not Defined! (#{self})" if profiler.debug?
        end
      }
      # Instance Methods
      klass.class_eval( &method_wrapper )
      # Class Methods
      metaklass = ( class << klass; self; end )
      metaklass.class_eval( &method_wrapper )
      nil
    end

  end # class TT::Profiler
end
