#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require_relative 'core.rb'

# Caches drawing instructions so complex calculations for generating the
# GL data can be reused.
#
# Redirect all Skethcup::View commands to a DrawCache object and call
# #render in a Tool's #draw event.
#
# @example
#   class Example    
#     def initialize( model )
#       @draw_cache = TT::DrawCache.new( model.active_view )
#     end
#     def deactivate( view )
#       @draw_cache.clear
#     end
#     def resume( view )
#       view.invalidate
#     end
#     def draw( view )
#       @draw_cache.render
#     end
#     def onLButtonUp( flags, x, y, view )
#       point = Geom::Point3d.new( x, y, 0 )
#       view.draw_points( point, 10, 1, 'red' )
#       view.invalidate
#     end
#   end
#
# @since 2.8.0
module SpeckleConnector
  class TT::DrawCache

    # @param [Sketchup::View] view
    #
    # @since 2.8.0
    def initialize( view )
      @view = view
      @commands = []
    end

    # Clears the cache. All drawing instructions are removed.
    #
    # @return [Nil]
    # @since 2.8.0
    def clear
      @commands.clear
      nil
    end

    # Draws the cached drawing instructions.
    #
    # @return [Sketchup::View]
    # @since 2.8.0
    def render
      view = @view
      for command in @commands
        view.send( *command )
      end
      view
    end

    # Cache drawing commands and data. These methods received the finsihed
    # processed drawing data that will be executed when #render is called.
    [
      :draw,
      :draw2d,
      :draw_line,
      :draw_lines,
      :draw_points,
      :draw_polyline,
      :draw_text,
      :drawing_color=,
      :line_stipple=,
      :line_width=,
      :set_color_from_line
    ].each { |symbol|
      define_method( symbol ) { |*args|
        @commands << args.unshift( this_method )
        @commands.size
      }
    }

    # Pass through methods to Sketchup::View so that the drawing cache object
    # can easily replace Sketchup::View objects in existing codes.
    #
    # @since 2.8.0
    def method_missing( *args )
      view = @view
      method = args.first
      if view.respond_to?( method )
        view.send(*args)
      else
        raise NoMethodError, "undefined method `#{method}' for #{self.class.name}"
      end
    end

    # @return [String]
    # @since 2.8.0
    def inspect
      hex_id = TT.object_id_hex( self )
      "#<#{self.class.name}:#{hex_id} Commands:#{@commands.size}>"
    end

    private

    # http://www.ruby-forum.com/topic/75258#895569
    def this_method
      ( caller[0] =~ /`([^']*)'/ and $1 ).intern
    end

  end # class TT::DrawCache
end
