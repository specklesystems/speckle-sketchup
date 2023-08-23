#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'geom3d.rb'
require_relative 'length.rb'
require_relative 'locale.rb'
require_relative 'sketchup.rb'

# @since 2.7.0

module SpeckleConnector
  module TT::Gizmo

    # @since 2.7.0
    class Manipulator

      CLR_X_AXIS    = Sketchup::Color.new( 255,   0,   0 )
      CLR_Y_AXIS    = Sketchup::Color.new(   0, 128,   0 )
      CLR_Z_AXIS    = Sketchup::Color.new(   0,   0, 255 )
      CLR_SELECTED  = Sketchup::Color.new( 255, 255,   0 )

      attr_reader( :origin, :axes )
      attr_accessor( :size )
      attr_reader( :callback, :callback_start, :callback_end )

      # @param [Geom::Point3d] origin
      # @param [Geom::Vector3d] xaxis
      # @param [Geom::Vector3d] yaxis
      # @param [Geom::Vector3d] zaxis
      #
      # @since 2.7.0
      def initialize( origin, xaxis, yaxis, zaxis )
        # Event callbacks
        @callback = nil
        @callback_start = nil
        @callback_end = nil

        @size = 150 # pixels

        # Origin
        @origin = origin

        # Set up axis and events
        @axes = []
        @axes << TT::Gizmo::Axis.new( self, @origin, xaxis, CLR_X_AXIS, CLR_SELECTED, :x )
        @axes << TT::Gizmo::Axis.new( self, @origin, yaxis, CLR_Y_AXIS, CLR_SELECTED, :y )
        @axes << TT::Gizmo::Axis.new( self, @origin, zaxis, CLR_Z_AXIS, CLR_SELECTED, :z )

        @active_axis = nil # Current Axis active due to a mouse down event.
        @mouse_axis = nil  # Current Axis the mouse hovers over.

        for axis in @axes
          axis.on_transform_start { |axis, action_name|
            @callback_start.call( action_name ) unless @callback_start.nil?
          }
          axis.on_transform_end { |axis, action_name|
            @callback_end.call( action_name ) unless @callback_end.nil?
          }
          axis.on_transform { |axis, t_increment, t_total, data|
            @origin = axis.origin
            update_axes( axis.origin, axis )
            @callback.call( t_increment, t_total, data ) unless @callback.nil?
          }
        end
      end

      # @return [Boolean]
      # @since 2.7.0
      def xaxis=( vector )
        @axes.x.direction = vector
      end

      # @return [Boolean]
      # @since 2.7.0
      def yaxis=( vector )
        @axes.y.direction = vector
      end

      # @return [Boolean]
      # @since 2.7.0
      def zaxis=( vector )
        @axes.z.direction = vector
      end

      # @return [Boolean]
      # @since 2.7.0
      def active?
        !@active_axis.nil?
      end

      # @since 2.7.0
      def tooltip
        for axis in @axes
          return axis.tooltip if axis.mouse_active?
        end
        ''
      end

      # @return [Geom::Vector3d]
      # @since 2.7.0
      def normal
        @axes.z.direction
      end

      # @since 2.7.0
      def on_transform( &block )
        @callback = block
      end

      # @since 2.7.0
      def on_transform_start( &block )
        @callback_start = block
      end

      # @since 2.7.0
      def on_transform_end( &block )
        @callback_end = block
      end

      # @param [Geom::Point3d] new_origin
      #
      # @return [Geom::Point3d]
      # @since 2.7.0
      def origin=( new_origin )
        @origin = new_origin
        for axis in @axes
          axis.origin = new_origin
        end
        new_origin
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onMouseMove( flags, x, y, view )
        # (!) Hotfix. Some times it appear that button up event is not detected
        #     and the gizmo thinks an axis is active. Some times due to cursor
        #     being released outside SketchUp's viewport or - it appear - with
        #     glitch that occur with quick clicks and released.
        if @active_axis && flags & MK_LBUTTON != MK_LBUTTON
          #puts 'Out of state!'
          #puts flags
          #puts @active_axis.id
          #puts '> Restore!'
          @active_axis = nil
        end

        if @active_axis
          @active_axis.onMouseMove( flags, x, y, view )
          return true
        else
          # Prioritise last axis the mouse hovered over.
          if @mouse_axis && @mouse_axis.onMouseMove( flags, x, y, view )
            return true
          else
            @mouse_axis = nil
          end

          # If the mouse doesn't interact with the last axis any more, check the
          # rest.
          for axis in @axes
            if axis.onMouseMove( flags, x, y, view )
              @mouse_axis = axis
              return true
            end
          end
        end
        @mouse_axis = nil
        false
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonDown( flags, x, y, view )
        for axis in @axes
          if axis.onLButtonDown( flags, x, y, view )
            @active_axis = axis
            return true
          end
        end
        false
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonUp( flags, x, y, view )
        for axis in @axes
          if axis.onLButtonUp( flags, x, y, view )
            @active_axis = nil
            return true
          end
        end
        false
      end

      # @param [Sketchup::View] view
      #
      # @return [Nil]
      # @since 2.7.0
      def draw( view )
        for axis in @axes
          axis.draw( view )
        end
        nil
      end

      # @since 2.7.0
      def mouse_over?
        !@mouse_axis.nil?
      end

      # @since 2.7.0
      def cancel
        for axis in @axes
          axis.cancel
        end
        reset()
      end

      private

      # @param [Geom::Point3d] origin
      # @param [TT::Gizmo::Axis] ignore_axis
      #
      # @return [Nil]
      # @since 2.7.0
      def update_axes( origin, ignore_axis )
        for a in @axes
          next if a == ignore_axis
          a.origin = origin
        end
        nil
      end

      # @since 2.7.0
      def reset
        @active_axis = nil
        @mouse_axis = nil
      end

    end # class Manipulator


    # @since 2.7.0
    class Axis

      attr_accessor( :origin, :direction )
      attr_reader( :parent, :id )

      # @param [Geom::Point3d] origin
      # @param [Geom::Vector3d] direction
      # @param [Sketchup::Color] color
      # @param [Sketchup::Color] active_color
      #
      # @since 2.7.0
      def initialize( parent, origin, direction, color, active_color, axis_id )
        @id = axis_id
        @parent = parent
        @origin = origin.clone
        @direction = direction.clone
        @color = color
        @active_color = active_color

        # Event callbacks
        @callback = nil
        @callback_start = nil
        @callback_end = nil

        # MoveGizmo
        @move_gizmo = MoveGizmo.new( self, origin, direction, color, active_color )
        @move_gizmo.on_transform_start { |gizmo, action_name|
          @callback_start.call( self, action_name ) unless @callback_start.nil?
        }
        @move_gizmo.on_transform { |gizmo, t_increment, t_total, data|
          @origin = gizmo.origin
          @rotate_gizmo.origin = gizmo.origin
          @scale_gizmo.origin = gizmo.origin
          @callback.call( self, t_increment, t_total, data ) unless @callback.nil?
        }
        @move_gizmo.on_transform_end { |gizmo, action_name|
          @callback_end.call( self, action_name ) unless @callback_end.nil?
        }

        # RotateGizmo
        @rotate_gizmo = RotateGizmo.new( self, origin, direction, color, active_color )
        @rotate_gizmo.on_transform_start { |gizmo, action_name|
          @callback_start.call( self, action_name ) unless @callback_start.nil?
        }
        @rotate_gizmo.on_transform { |gizmo, t_increment, t_total, data|
          @callback.call( self, t_increment, t_total, data ) unless @callback.nil?
        }
        @rotate_gizmo.on_transform_end { |gizmo, action_name|
          @callback_end.call( self, action_name ) unless @callback_end.nil?
        }

        # ScaleGizmo
        @scale_gizmo = ScaleGizmo.new( self, origin, direction, color, active_color )
        @scale_gizmo.on_transform_start { |gizmo, action_name|
          @callback_start.call( self, action_name ) unless @callback_start.nil?
        }
        @scale_gizmo.on_transform { |gizmo, t_increment, t_total, data|
          @callback.call( self, t_increment, t_total, data ) unless @callback.nil?
        }
        @scale_gizmo.on_transform_end { |gizmo, action_name|
          @callback_end.call( self, action_name ) unless @callback_end.nil?
        }
      end

      # @return [String]
      # @since 2.7.0
      def inspect
        hex_id = TT.object_id_hex( self )
        "#<#{self.class.name}:#{hex_id} #{@direction}>"
      end

      # @since 2.7.0
      def on_transform( &block )
        @callback = block
      end

      # @since 2.7.0
      def on_transform_start( &block )
        @callback_start = block
      end

      # @since 2.7.0
      def on_transform_end( &block )
        @callback_end = block
      end

      # @return [Boolean]
      # @since 2.7.0
      def active?
        @move_gizmo.active? || @rotate_gizmo.active? || @scale_gizmo.active?
      end

      # @since 2.7.0
      def tooltip
        if @move_gizmo.mouse_active?
          @move_gizmo.tooltip
        elsif @rotate_gizmo.mouse_active?
          @rotate_gizmo.tooltip
        elsif @scale_gizmo.mouse_active?
          @scale_gizmo.tooltip
        else
          ''
        end
      end

      # @return [Boolean]
      # @since 2.7.0
      def mouse_active?
        @mouse_active == true
      end

      # @param [Geom::Point3d] new_origin
      #
      # @return [Geom::Point3d]
      # @since 2.7.0
      def origin=( new_origin )
        @origin = new_origin.clone
        @move_gizmo.origin = @origin
        @rotate_gizmo.origin = @origin
        @scale_gizmo.origin = @origin
      end

      # @param [Geom::Vector3d] vector
      #
      # @return [Geom::Vector3d]
      # @since 2.7.0
      def direction=( vector )
        @direction = vector.clone
        @move_gizmo.direction = @direction.clone
        @rotate_gizmo.direction = @direction.clone
        @scale_gizmo.direction = @direction.clone
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonDown( flags, x, y, view )
        camera = view.camera
        perpendicular = !camera.perspective? && camera.direction.perpendicular?( @direction )
        can_move   = !(@rotate_gizmo.active? || @scale_gizmo.active?)
        can_rotate = !(@move_gizmo.active? || @scale_gizmo.active?) && !perpendicular
        can_scale  = !(@move_gizmo.active? || @rotate_gizmo.active?)
        if can_move && @move_gizmo.onLButtonDown( flags, x, y, view )
          true
        elsif can_rotate && @rotate_gizmo.onLButtonDown( flags, x, y, view )
          true
        elsif can_scale && @scale_gizmo.onLButtonDown( flags, x, y, view )
          true
        else
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonUp( flags, x, y, view )
        can_move   = !(@rotate_gizmo.active? || @scale_gizmo.active?)
        can_rotate = !(@move_gizmo.active? || @scale_gizmo.active?)
        can_scale  = !(@move_gizmo.active? || @rotate_gizmo.active?)
        if can_move && @move_gizmo.onLButtonUp( flags, x, y, view )
          true
        elsif can_rotate && @rotate_gizmo.onLButtonUp( flags, x, y, view )
          true
        elsif can_scale && @scale_gizmo.onLButtonUp( flags, x, y, view )
          true
        elsif @interacting
          # (!) ...
          @callback_end.call( self ) unless @callback_end.nil?
          @interacting = false
          true
        else
          @interacting = false
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onMouseMove( flags, x, y, view )
        camera = view.camera
        perpendicular = !camera.perspective? && camera.direction.perpendicular?( @direction )
        if @interacting
          # (!) ...
          @mouse_active = true
          true
        else
          can_move   = !(@rotate_gizmo.active? || @scale_gizmo.active?)
          can_rotate = !(@move_gizmo.active? || @scale_gizmo.active?) && !perpendicular
          can_scale  = !(@move_gizmo.active? || @rotate_gizmo.active?)
          if can_move && @move_gizmo.onMouseMove( flags, x, y, view )
            @mouse_active = true
            view.invalidate
            return true
          elsif can_rotate && @rotate_gizmo.onMouseMove( flags, x, y, view )
            @mouse_active = true
            view.invalidate
            return true
          elsif can_scale && @scale_gizmo.onMouseMove( flags, x, y, view )
            @mouse_active = true
            view.invalidate
            return true
          end
          @mouse_active = false
          false
        end
      end

      # @param [Sketchup::View] view
      #
      # @return [Nil]
      # @since 2.7.0
      def draw( view )
        @move_gizmo.draw( view )
        @rotate_gizmo.draw( view )
        @scale_gizmo.draw( view )
      end

      # @since 2.7.0
      def cancel
        @move_gizmo.cancel
        @rotate_gizmo.cancel
        @scale_gizmo.cancel
      end

    end # class Axis


    # @since 2.7.0
    class MoveGizmo

      attr_accessor( :origin, :direction )

      # @param [Geom::Point3d] origin
      # @param [Geom::Vector3d] direction
      # @param [Sketchup::Color] color
      # @param [Sketchup::Color] active_color
      #
      # @since 2.7.0
      def initialize( parent, origin, direction, color, active_color )
        @parent = parent
        @origin = origin.clone
        @direction = direction.clone
        @color = color
        @active_color = active_color

        @selected = false
        @interacting = false

        # Cache of the axis origin and orientation. Cached on onLButtonDown
        @old_origin = nil
        @old_vector = nil
        @old_axis = nil # [pt1, pt2]

        # User InputPoint
        @ip = Sketchup::InputPoint.new

        @pt_start = nil # Startpoint - IP projected to selected axis
        @pt_screen_start = nil # Screen projection of @pt_start

        @pt_mouse = nil # Mouse Point3d - projected to selected axis
        @pt_screen_mouse = nil

        # Event callbacks
        @callback = nil
        @callback_start = nil
        @callback_end = nil
      end

      # @since 2.7.0
      def on_transform( &block )
        @callback = block
      end

      # @since 2.7.0
      def on_transform_start( &block )
        @callback_start = block
      end

      # @since 2.7.0
      def on_transform_end( &block )
        @callback_end = block
      end

      # @return [Boolean]
      # @since 2.7.0
      def active?
        @interacting == true
      end

      # @return [Boolean]
      # @since 2.7.0
      def mouse_active?
        @mouse_active == true
      end

      # @since 2.7.0
      def tooltip
        'Move'
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonDown( flags, x, y, view )
        if @selected
          @interacting = true

          # Cache the origin for use in onMouseMove to work out the distance
          # moved.
          @old_origin = @origin.clone
          @old_axis = [ @origin, @origin.offset( @direction, 10 ) ] # Line (3D)

          # Get input point closest to the selected axis
          ip = view.inputpoint( x, y )
          @pt_start = ip.position.project_to_line( [@origin, @direction] )

          # Project to screen axis
          screen_point = Geom::Point3d.new( x, y, 0 )
          screen_axis = screen_points( @old_axis, view )
          @pt_screen_start = screen_point.project_to_line( screen_axis )

          @callback_start.call( self, 'Move' ) unless @callback_start.nil?
          true
        else
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonUp( flags, x, y, view )
        if @interacting
          @ip.clear
          @callback_end.call( self, 'Move' ) unless @callback_end.nil?
          @interacting = false
          true
        else
          @interacting = false
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onMouseMove(flags, x, y, view)
        if @interacting
          @mouse_active = true
          move_event( x, y, view ) # return true
        else
          @selected = mouse_over?( x, y, view )
          @mouse_active = @selected
        end
      end

      # @param [Sketchup::View] view
      #
      # @return [Nil]
      # @since 2.7.0
      def draw( view )
        # Arrow Body
        segment = modelspace_segment( view )
        segment2d = segment.map { |point| view.screen_coords( point ) }
        view.line_stipple = ''
        view.line_width = 2
        view.drawing_color = (@selected) ? @active_color : @color
        view.draw2d( GL_LINES, segment2d )

        # Arrowhead
        segments = arrow_segments( view )
        # Arrowhead Edges
        view.line_stipple = ''
        view.line_width = 2
        view.drawing_color = (@selected) ? @active_color : @color
        for segment in segments
          screen_points = segment.map { |point| view.screen_coords( point ) }
          view.draw2d( GL_LINE_STRIP, screen_points )
        end
        # Arrowhead Fill
        if TT::SketchUp.support?( TT::SketchUp::COLOR_ALPHA )
          circle = segments.last
          tip = segments.first.last
          triangles = []
          (0...circle.size-1).each { |i|
            triangles << circle[ i ]
            triangles << circle[ i+1 ]
            triangles << tip
          }
          color = Sketchup::Color.new( *@color.to_a )
          color.alpha = 45
          view.drawing_color = color
          screen_points = triangles.map { |point| view.screen_coords( point ) }
          view.draw2d( GL_TRIANGLES, screen_points )
        end
      end

      # @since 2.7.0
      def cancel
        @selected = false
        @interacting = false
      end

      private

      # @param [Sketchup::View] view
      #
      # @return [Array<Array<Geom::Point3d>>]
      # @since 2.7.0
      def arrow_segments( view )
        base    = view.pixels_to_model( 110, @origin )  # (!) Make Constant
        tip     = view.pixels_to_model( 150, @origin )
        radius  = view.pixels_to_model(  10, @origin )

        base_pt = ORIGIN.offset( Z_AXIS, base )
        tip_pt  = ORIGIN.offset( Z_AXIS, tip )

        # Arrow base.
        circle = TT::Geom3d.circle( base_pt, Z_AXIS, radius, 8 )

        # Connect base circle to arrow tip.
        segments = []
        for point in circle
          segments << [ point, tip_pt ]
        end

        # Since the segments are drawn with GL_LINE_STRIP we need to manually close
        # the circle to form a loop.
        circle << circle.first
        segments << circle

        # Transform the segment into correct model space.
        tr = Geom::Transformation.new( @origin, @direction )
        for segment in segments
          segment.map! { |point| point.transform( tr ) }
        end

        segments
      end

      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def mouse_over?( x, y, view )
        ph = view.pick_helper
        ph.do_pick( x,y )

        segment = modelspace_segment( view )
        result = ph.pick_segment( segment, x, y, 10 )
        return true if result

        for segment in arrow_segments( view )
          result = ph.pick_segment( segment, x, y )
          return true unless result == false
        end

        false
      end

      # @param [Array<Geom::Point3d>] points
      # @param [Sketchup::View] view
      #
      # @return [Array<Geom::Point3d>]
      # @since 2.7.0
      def screen_points( points, view )
        points.map { |pt|
          screen_pt = view.screen_coords( pt )
          screen_pt.z = 0
          screen_pt
        }
      end

      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def modelspace_segment( view )
        model_length = view.pixels_to_model( 110, @origin ) # (!) Make Constant
        [ @origin, @origin.offset( @direction, model_length ) ]
      end

      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def move_event( x, y, view )
        # Axis vector
        vector = @old_axis[0].vector_to( @old_axis[1] )

        # Get mouse point on selected axis
        @ip.pick(view, x, y)
        @pt_mouse = @ip.position.project_to_line( @old_axis )

        # Get axis in screen space
        screen_axis = screen_points( @old_axis, view )

        # Calculate the Screen offset distance
        @pt_screen_mouse = Geom::Point3d.new( x, y, 0 ).project_to_line( screen_axis )
        mouse_distance = @pt_screen_start.distance( @pt_screen_mouse )

        if mouse_distance > 0
          # Direction vector
          direction = vector.clone

          # Get movement vector in screen space
          v = @pt_screen_start.vector_to( @pt_screen_mouse )

          # (!) validate vector.
          screen_v = screen_axis[0].vector_to( screen_axis[1] )
          direction.reverse! unless screen_v.samedirection?( v )

          # Work out how much in real world distance the offset is.
          screen_distance = v.length
          world_distance = view.pixels_to_model( screen_distance, @old_origin )

          # Use model's snap length settings.
          unit_option = view.model.options['UnitsOptions']
          if unit_option['LengthSnapEnabled']
            snap_length = unit_option['LengthSnapLength']
            world_distance = TT::Length.snap( world_distance, snap_length )
          end

          # UI Feedback.
          distance_formatted = world_distance.to_l.to_s
          Sketchup.vcb_label = 'Distance'
          Sketchup.vcb_value = distance_formatted
          view.tooltip = "Distance: #{distance_formatted}"

          # Offset Origin
          offset = @old_origin.offset( direction, world_distance )

          # Global Offset Vectors
          v_increment  = @origin.vector_to( offset )
          v_total = @old_origin.vector_to( offset )

          # Move Gizmo Origin
          t_total = Geom::Transformation.new( v_total )
          @origin = @old_origin.transform( t_total )

          data = [ :move, v_total ]

          # Call event with local transformations
          t_increment  = Geom::Transformation.new( v_increment )
          t_total = Geom::Transformation.new( v_total )
          @callback.call( self, t_increment, t_total, data ) unless @callback.nil?
        end
        true
      end

    end # class MoveGizmo


    # @deprecated Unfinished
    # @since 2.7.0
    class RotateGizmo

      attr_accessor( :origin, :direction )

      # @param [Geom::Point3d] origin
      # @param [Geom::Vector3d] direction
      # @param [Sketchup::Color] color
      # @param [Sketchup::Color] active_color
      #
      # @since 2.7.0
      def initialize( parent, origin, direction, color, active_color )
        @parent = parent
        @origin = origin.clone
        @direction = direction.clone
        @color = color
        @active_color = active_color

        @selected = false
        @interacting = false

        # Cache of the axis origin and orientation. Cached on onLButtonDown
        @old_origin = nil
        @old_vector = nil
        @old_axis = nil # [pt1, pt2]

        # User InputPoint
        @pt_screen_start = nil
        @pt_screen_mouse = nil

        @pt_start = nil
        @pt_mouse = nil

        # Event callbacks
        @callback = nil
        @callback_start = nil
        @callback_end = nil
      end

      # @since 2.7.0
      def on_transform( &block )
        @callback = block
      end

      # @since 2.7.0
      def on_transform_start( &block )
        @callback_start = block
      end

      # @since 2.7.0
      def on_transform_end( &block )
        @callback_end = block
      end

      # @return [Boolean]
      # @since 2.7.0
      def active?
        @interacting == true
      end

      # @return [Boolean]
      # @since 2.7.0
      def mouse_active?
        @mouse_active == true
      end

      # @since 2.7.0
      def tooltip
        'Rotate'
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonDown( flags, x, y, view )
        if @selected

          # Cache the origin for use in onMouseMove to work out the distance
          # moved.
          @old_origin = @origin.clone
          @old_axis = [ @origin.clone, @direction.clone ] # Line (3D)

          @pt_screen_start = Geom::Point3d.new( x, y, 0 )
          @pt_screen_mouse = @pt_screen_start.clone

          segment = rotation_segment( view )
          @pt_start = project_to_segment( view, x, y, segment )
          if @pt_start
            @pt_mouse = @pt_start.clone
          else
            @pt_mouse = nil
            return true
          end

          @last_vector = @origin.vector_to( @pt_start )
          @angle = 0
          @last_angle = 0

          @interacting = true
          @callback_start.call( self, 'Rotate' ) unless @callback_start.nil?
          true
        else
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonUp( flags, x, y, view )
        if @interacting
          @callback_end.call( self, 'Rotate' ) unless @callback_end.nil?
          @interacting = false
          true
        else
          @interacting = false
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onMouseMove( flags, x, y, view )
        if @interacting
          @mouse_active = true

          segment = rotation_segment( view )
          screen_point = Geom::Point3d.new( x, y, 0 )

          @pt_mouse = project_to_segment( view, x, y, segment )
          return false unless @pt_mouse

          start_vector = @origin.vector_to( @pt_start )
          mouse_vector = @origin.vector_to( @pt_mouse )

          clockwise = ( start_vector * mouse_vector % @direction ) < 0

          total_angle = start_vector.angle_between( mouse_vector )

          if clockwise
            total_angle = total_angle * -1
          end

          # Snapping
          a = total_angle
          unit_options = view.model.options['UnitsOptions']
          if unit_options['AngleSnapEnabled']
            snap_angle = unit_options['SnapAngle'].degrees
            size = view.pixels_to_model( 150, @origin ) # Protractor size
            # Closest snap
            diff = a % snap_angle
            if diff > snap_angle / 2.0
              nearest_angle = a + (snap_angle - diff)
            else
              nearest_angle = a - diff
            end
            # Snapping behaviour depends if the cursor is within the Gizmo radius.
            mouse_ray = view.pickray( x, y )
            plane = [ @origin, @direction ]
            plane_point = Geom::intersect_line_plane( mouse_ray, plane )
            mouse_plane_vector = @origin.vector_to( plane_point )
            #if mouse_vector.length < size
            if mouse_plane_vector.length < size
              # Within the Gizmo radius - Full snap
              a = nearest_angle
            else
              # Outside the Gizmo radius - Proximity snap
              #rotation = (direction < 0.0) ? -nearest_angle : nearest_angle
              #rotation = (clockwise) ? -nearest_angle : nearest_angle
              rotation = nearest_angle
              tr = Geom::Transformation.rotation( @origin, @direction, rotation )
              line = [ @origin, @pt_start.transform(tr) ]

              nx = view.pixels_to_model( 5, @pt_mouse )
              ny = @pt_mouse.project_to_line(line).distance( @pt_mouse )

              a = nearest_angle if ny < nx # Snap!
            end
            # Adjust increment snap.
            if a != total_angle
              total_angle = a
            end
          end # if snapping
          @angle = total_angle

          t_total = Geom::Transformation.rotation( @origin, @direction, total_angle )

          increment_angle = total_angle - @last_angle
          t_increment = Geom::Transformation.rotation( @origin, @direction, increment_angle )

          angle_formatted = Sketchup.format_angle( total_angle )
          Sketchup.vcb_label = 'Angle'
          Sketchup.vcb_value = angle_formatted
          view.tooltip = "Rotate: #{angle_formatted}"

          @pt_screen_mouse = screen_point # (?) Unused?
          @last_angle = total_angle

          data = [ :rotate, @parent.origin, @direction, total_angle ]

          @callback.call( self, t_increment, t_total, data ) unless @callback.nil?
          true
        else
          @selected = mouse_over?( x, y, view )
          @mouse_active = @selected
        end
      end

      # @param [Sketchup::View] view
      #
      # @return [Nil]
      # @since 2.7.0
      def draw( view )
        points = rotation_segment( view )
        screen_pts = screen_points( points, view )

        view.line_stipple = ''
        view.line_width = 2
        view.drawing_color = (@selected) ? @active_color : @color
        view.draw2d( GL_LINE_STRIP, screen_pts )

        if @interacting && @pt_start && @pt_mouse
          angle = @angle

          view.line_stipple = ''
          view.line_width = 1

          # Account for snapping
          start_vector = @origin.vector_to( @pt_start )
          tr = Geom::Transformation.rotation( @origin, @direction, angle )
          mouse_vector = start_vector.transform( tr )

          # Start Line
          view.drawing_color = @color
          view.draw( GL_LINES, [@origin, @pt_start] )

          # End Line
          view.drawing_color = @color
          #view.draw( GL_LINES, [@origin, @pt_mouse] )
          pt2 = @origin.offset( mouse_vector )
          view.draw( GL_LINES, [@origin, pt2] )

          # Rotation Pie
          #start_vector = @origin.vector_to( @pt_start )
          #mouse_vector = @origin.vector_to( @pt_mouse )
          clockwise = ( start_vector * mouse_vector % @direction ) < 0

          # Generate ticks
          unit_options = view.model.options['UnitsOptions']
          if unit_options['AngleSnapEnabled']
            radius = view.pixels_to_model( 150, @origin )
            tick_length = view.pixels_to_model( 150 / 12, @origin )
            steps = 360.0 / unit_options['SnapAngle']
            ticks = TT::Geom3d.circle2d( ORIGIN, X_AXIS, radius, steps )
            ticks.map! { |pt| [ pt, pt.offset( pt.vector_to(ORIGIN), tick_length ) ] }
            ticks.flatten!
            yaxis = start_vector * @direction
            tr = Geom::Transformation.axes( @origin, start_vector, yaxis, @direction )
            for pt in ticks
              pt.transform!( tr )
            end
            view.draw( GL_LINES, ticks )
          end

          # Rotation Pie
          segments = TT::Geom3d.arc_segments( angle, 64 )

          if TT::SketchUp.support?( TT::SketchUp::COLOR_ALPHA ) && @selected
            fill = Sketchup::Color.new( *@color.to_a )
            radius = view.pixels_to_model( 150, @origin )

            # Rotated Segment
            fill.alpha = 0.4
            view.drawing_color = fill
            arc = TT::Geom3d.arc( @origin, start_vector, @direction, radius, 0, angle, segments )
            polygon = arc + [@origin]
            view.draw( GL_POLYGON, polygon )

            # Unrotated Segment
            # First 180 - because OpenGL only draws convex shapes.
            half = ( clockwise ) ? -180.degrees : 180.degrees
            rest_angle = ( half - angle ) * -1
            half = half * -1 if rest_angle.abs == 360.degrees # Edge case
            fill.alpha = 0.2
            view.drawing_color = fill
            segments = TT::Geom3d.arc_segments( half, 64 )
            arc = TT::Geom3d.arc( @origin, mouse_vector, @direction, radius, 0, half, segments )
            polygon = arc + [@origin]
            view.draw( GL_POLYGON, polygon )
            # Remainding Segment
            #rest_angle = ( half - angle ) * -1
            if rest_angle.abs != 360.degrees
              segments = TT::Geom3d.arc_segments( rest_angle, 64 )
              arc = TT::Geom3d.arc( @origin, start_vector, @direction, radius, 0, rest_angle, segments )
              polygon = arc + [@origin]
              view.draw( GL_POLYGON, polygon )
            end
          end

          view.line_width = 1
          view.drawing_color = @color
          segments = TT::Geom3d.arc_segments( angle, 64 )

          for offset in [ 50, 75, 100, 125 ]
            radius = view.pixels_to_model( offset, @origin )
            arc = TT::Geom3d.arc( @origin, start_vector, @direction, radius, 0, angle, segments )
            view.draw( GL_LINE_STRIP, arc )
          end

        end
      end

      # @since 2.7.0
      def cancel
        @selected = false
        @interacting = false
      end

      private

      # Return the full orientation of the two lines. Going counter-clockwise.
      #
      # @return [Float]
      # @since 2.7.0
      def full_angle_between( vector1, vector2, normal = Z_AXIS )
        direction = ( vector1 * vector2 ) % normal
        angle = vector1.angle_between( vector2 )
        angle = 360.degrees - angle if direction < 0.0
        return angle
      end


      # @param [Sketchup::View] view
      #
      # @return [Geom::Point3d, Nil]
      # @since 2.7.0
      def project_to_segment( view, x, y, segment )
        screen_point = Geom::Point3d.new( x, y, 0 )
        ray = view.pickray( x, y )
        center = @origin
        plane = [ center, @direction ]
        point_on_plane = Geom::intersect_line_plane( ray, plane )
        return nil unless point_on_plane
        mouse_line = [ center, point_on_plane ]
        #
        closest_distance = nil
        closest_point = nil
        (0...segment.size-1).each { |i|
          line = segment[i, 2]
          pt1 = Geom.intersect_line_line( mouse_line, line )
          next unless pt1
          next unless TT::Point3d.between?( line[0], line[1], pt1 )
          vector_to_segment = center.vector_to( pt1 )
          vector_to_mouse = center.vector_to( point_on_plane )
          next unless vector_to_mouse.samedirection?( vector_to_segment )
          distance = center.distance( pt1 )
          if closest_distance.nil? || distance < closest_distance
            closest_distance = distance
            closest_point = pt1
          end
        }
        closest_point
      rescue ArgumentError => error
        p ray
        p plane
        p mouse_line
        p line
        raise
      end

      # @param [Sketchup::View] view
      #
      # @return [Array<Array<Geom::Point3d>>]
      # @since 2.7.0
      def rotation_segment( view )
        # Generate Circle
        radius = view.pixels_to_model( @parent.parent.size, @origin )

        # The rotation gizmo is based on the gimbal in Rhino5:
        # * A quarter circle is displayed when the user is not interacting.
        # * A full circle is displayed when the user interacts with the rotation
        #   gizmo.
        if @interacting
          segments = TT::Geom3d.circle( @origin, @direction, radius, 64 )
          # Since the segments are drawn with GL_LINE_STRIP we need to manually close
          # the circle to form a loop.
          segments << segments.first
        else
          # Find the axis that represent the relative X axis for the current axis.
          # @direction.axes.x is not reliable as it can produce normals inverse
          # from what is wanted.
          #
          # The axis is chosen to be n + 1 where n is the index of the current
          # axis in the root manipulator.
          #
          # This will yield correct results:
          # * Current Axis X yields Axis Y
          # * Current Axis Y yields Axis Z
          # * Current Axis Z yields Axis X
          axes = @parent.parent.axes
          index = axes.index( @parent )
          x_index = ( index + 1 ) % axes.size
          y_index = ( index + 2 ) % axes.size
          relative_x_axis = axes[ x_index ].direction
          relative_y_axis = axes[ y_index ].direction
          orientation = @direction * relative_x_axis % relative_y_axis
          # The angles of the arc will depend if the parent group, component is
          # flipped in an odd number of directions.
          if orientation > 0
            # Normal Axes
            start_angle = 180.degrees
            end_angle = 270.degrees
          else
            # Flipped Axes
            start_angle = 90.degrees
            end_angle = 180.degrees
          end
          segments = TT::Geom3d.arc(
            @origin, relative_x_axis, @direction,
            radius, start_angle, end_angle, 16 )
        end

        segments
      end

      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def mouse_over?( x, y, view )
        ph = view.pick_helper
        ph.do_pick( x,y )
        segment = rotation_segment( view )
        result = ph.pick_segment( segment, x, y, 15 )
        return true unless result == false
        false
      end

      # @param [Array<Geom::Point3d>] points
      # @param [Sketchup::View] view
      #
      # @return [Array<Geom::Point3d>]
      # @since 2.7.0
      def screen_points( points, view )
        points.map { |pt|
          screen_pt = view.screen_coords( pt )
          screen_pt.z = 0
          screen_pt
        }
      end

    end # class RotateGizmo


    # @deprecated Unfinished
    # @since 2.7.0
    class ScaleGizmo

      SIZE = 170

      attr_accessor( :origin, :direction )

      # @param [Geom::Point3d] origin
      # @param [Geom::Vector3d] direction
      # @param [Sketchup::Color] color
      # @param [Sketchup::Color] active_color
      #
      # @since 2.7.0
      def initialize( parent, origin, direction, color, active_color )
        @parent = parent
        @origin = origin.clone
        @direction = direction.clone
        @color = color
        @active_color = active_color

        @selected = false
        @interacting = false

        # Cache of the axis origin and orientation. Cached on onLButtonDown
        @old_origin = nil
        @old_vector = nil
        @old_axis = nil # [pt1, pt2]

        # User InputPoint
        @pt_screen_start = nil
        @pt_screen_mouse = nil

        @pt_start = nil
        @pt_mouse = nil

        # Event callbacks
        @callback = nil
        @callback_start = nil
        @callback_end = nil
      end

      # @since 2.7.0
      def on_transform( &block )
        @callback = block
      end

      # @since 2.7.0
      def on_transform_start( &block )
        @callback_start = block
      end

      # @since 2.7.0
      def on_transform_end( &block )
        @callback_end = block
      end

      # @return [Boolean]
      # @since 2.7.0
      def active?
        @interacting == true
      end

      # @return [Boolean]
      # @since 2.7.0
      def mouse_active?
        @mouse_active == true
      end

      # @since 2.7.0
      def tooltip
        'Scale'
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonDown( flags, x, y, view )
        if @selected
          # Cache the origin for use in onMouseMove to work out the distance
          # moved.
          @old_origin = @origin.clone
          @old_axis = [ @origin.clone, @direction.clone ] # Line (3D)

          #@pt_screen_start = Geom::Point3d.new( x, y, 0 )
          #@pt_screen_mouse = @pt_screen_start.clone

          # Find the closest point on the segments from where the mouse is.
          segments = gripper_segments( view )
          @pt_start = project_to_segment( view, x, y, segments, 10.0 )
          return true unless @pt_start

          #@last_vector = @origin.vector_to( @pt_start )
          @last_scale = 1.0

          @interacting = true
          @callback_start.call( self, 'Scale' ) unless @callback_start.nil?
          true
        else
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onLButtonUp( flags, x, y, view )
        @pt_mouse = nil
        if @interacting
          @callback_end.call( self, 'Scale' ) unless @callback_end.nil?
          @interacting = false
          true
        else
          @interacting = false
          false
        end
      end

      # @param [Integer] flags
      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def onMouseMove( flags, x, y, view )
        if @interacting
          @mouse_active = true

          segments = gripper_segments( view )
          screen_point = Geom::Point3d.new( x, y, 0 )

          @pt_mouse = project_to_segment( view, x, y, segments )
          return false unless @pt_mouse

          start_vector = @origin.vector_to( @pt_start )
          mouse_vector = @origin.vector_to( @pt_mouse )

          # Prevent scaling in negative direction.
          if mouse_vector.valid? && mouse_vector.samedirection?( @direction )
            mouse_vector.length = 0
            @pt_mouse = @origin.clone
          end

          total_scale = mouse_vector.length / start_vector.length
          if @last_scale == 0
            increment_scale = 0
          else
            increment_scale = total_scale / @last_scale
          end

          # Increment
          scaling = scale_array( @parent, increment_scale, flags )
          t_increment = Geom::Transformation.scaling( *scaling ) # rubocop:disable SketchupBugs/UniformScaling

          # Total
          scaling = scale_array( @parent, total_scale, flags )
          t_total = Geom::Transformation.scaling( *scaling ) # rubocop:disable SketchupBugs/UniformScaling

          @last_scale = total_scale

          scale_formatted = TT::Locale.float_to_string( total_scale, 2 )
          Sketchup.vcb_label = 'Scale'
          Sketchup.vcb_value = scale_formatted
          view.tooltip = "Scale: #{scale_formatted}"

          mask = scale_mask( @parent, flags )
          data = [ :scale, @parent.origin, total_scale, mask ]


          # Convert the local scaling transformation into global transformation.
          gizmo = @parent.parent
          gx, gy, gz = gizmo.axes.map { |axis|
            axis.direction
          }
          go = gizmo.origin
          gizmo_tr = Geom::Transformation.new( gx, gy, gz, go )

          t_increment = gizmo_tr * t_increment * gizmo_tr.inverse
          t_total     = gizmo_tr * t_total * gizmo_tr.inverse

          @callback.call( self, t_increment, t_total, data ) unless @callback.nil?
          true
        else
          @selected = mouse_over?( x, y, view )
          @mouse_active = @selected
        end
      end

      # @return [Array]
      # @since 2.7.0
      def scale_array( axis, scale, flags )
        origin_pt = ORIGIN.clone
        if flags & CONSTRAIN_MODIFIER_MASK == CONSTRAIN_MODIFIER_MASK
          [ origin_pt, scale, scale, scale ]
        else
          case axis.id
          when :x
            [ origin_pt, scale, 1, 1 ]
          when :y
            [ origin_pt, 1, scale, 1 ]
          when :z
            [ origin_pt, 1, 1, scale ]
          end
        end
      end

      # @return [Array]
      # @since 2.7.0
      def scale_mask( axis, flags )
        if flags & CONSTRAIN_MODIFIER_MASK == CONSTRAIN_MODIFIER_MASK
          [ true, true, true ]
        else
          case axis.id
          when :x
            [ true, false, false ]
          when :y
            [ false, true, false ]
          when :z
            [false, false, true ]
          end
        end
      end

      # @param [Sketchup::View] view
      #
      # @return [Nil]
      # @since 2.7.0
      def draw( view )
        size = view.pixels_to_model( SIZE, @origin )

        if @pt_mouse
          pt = @pt_mouse
        else
          pt = @origin.offset( @direction.reverse, size )
        end

        pt1 =  view.screen_coords( @origin )
        pt2 =  view.screen_coords( pt )

        color = (@selected) ? @active_color : @color
        view.drawing_color = color

        view.line_stipple = '-'
        view.line_width = 2
        view.draw2d( GL_LINE_STRIP, pt1, pt2 )

        view.line_stipple = ''
        view.draw_points( [pt], 8, 1, color )

        #if @pt_mouse
        #view.line_stipple = ''
        #  view.draw_points( [@pt_mouse], 8, 4, @active_color)
        #end

        view.draw2d( GL_LINE_STRIP, [-100,-100,0], [-50,-50,0] ) # Hack
      end

      # @since 2.7.0
      def cancel
        @selected = false
        @interacting = false
        @pt_mouse = nil
      end

      private


      # @param [Sketchup::View] view
      #
      # @return [Geom::Point3d, Nil]
      # @since 2.7.0
      def project_to_segment( view, x, y, segments, aperture = nil )
        # Get a ray from the cursor which projects into the model.
        ray = view.pickray( x, y )
        # Find the closest intersecting with the segments.
        line = segments
        pt1, pt2 = Geom.closest_points( line, ray )
        # If an aperture is given it must be within the given range from the
        # pickray.
        if aperture
          vector_between = pt1.vector_to( pt2 )
          pick_aperture = view.pixels_to_model( aperture / 2.0, pt1 )
          return nil unless vector_between.length <= pick_aperture
        end
        # Return point on segment.
        pt1
      end

      # @param [Sketchup::View] view
      #
      # @return [Array<Array<Geom::Point3d>>]
      # @since 2.7.0
      def gripper_segments( view )
        size = view.pixels_to_model( SIZE, @origin )

        pt1 = @origin.clone
        pt2 = @origin.offset( @direction.reverse, size )

        [pt1, pt2]
      end

      # @param [Integer] x
      # @param [Integer] y
      # @param [Sketchup::View] view
      #
      # @return [Boolean]
      # @since 2.7.0
      def mouse_over?( x, y, view )
        ph = view.pick_helper
        ph.do_pick( x,y )
        segments = gripper_segments( view )
        result = ph.pick_segment( segments, x, y, 15 )
        return true unless result == false
        false
      end

      # @param [Array<Geom::Point3d>] points
      # @param [Sketchup::View] view
      #
      # @return [Array<Geom::Point3d>]
      # @since 2.7.0
      def screen_points( points, view )
        points.map { |pt|
          screen_pt = view.screen_coords( pt )
          screen_pt.z = 0
          screen_pt
        }
      end

    end # class ScaleGizmo

  end # module TT::Gizmo
end
