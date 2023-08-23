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
  module TT

    # Outputs debug data.
    #
    # Under Windows the data is sent to OutputDebugString and
    # requires a utility like DebugView to see the data. Without it the call
    # is muted.
    #
    # Under other platforms the data is sent to the console.
    #
    # @param [Mixed] data
    #
    # @return [Nil]
    # @since 2.5.0
    def self.debug(data)
      if data.is_a?( String )
        str = data
      else
        str = data.inspect
      end
      if TT::System.is_windows?
        if TT::Win32.respond_to?(:debug_output)
          TT::Win32.debug_output(str)
        else
          TT::Win32::OutputDebugString.call( "#{str}\n\0" )
        end
      else
        puts data
      end
      nil
    end

    # @since 2.7.0
    class Debug

      # @param [String] object
      #
      # @return [Array]
      # @since 2.7.0
      def self.map_methods( object, ignore = [Kernel, Object] )
        klass = ( object.class == Class || object.class == Module ) ? object : object.class
        methods = klass.instance_methods
        klasses = {}
        ancestors = klass.ancestors
        puts "#{klass} - (#{klass.class})"
        puts "> Ancestors: #{ancestors.inspect}"
        for k in ancestors
          puts "  > #{k} - ( #{k.class})"
          if ignore.include?( k )
            puts "    (Ignored)"
          else
            puts "      #{k.instance_methods(false).sort.join( "\n      " )}"
          end
        end
        nil
      end

    end # class Debug

  end # module TT
end
