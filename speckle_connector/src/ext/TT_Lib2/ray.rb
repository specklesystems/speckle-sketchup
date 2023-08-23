#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'sketchup.rb'

module SpeckleConnector
  # Wrapper class for Model.raytest with enhanced features.
  #
  # @since 2.0.0
  class TT::Ray

    # @overload new(ray)
    #   @param [Array<Sketchup::Point3d,Sketchup::Vector3d>] value
    # @overload new(ray)
    #   @param [Array<Sketchup::Point3d,Sketchup::Point3d>] value
    # @overload new(point, vector)
    #   @param [Sketchup::Point3d] point
    #   @param [Sketchup::Vector3d] vector
    # @overload new(point1, point2)
    #   @param [Sketchup::Point3d] point1
    #   @param [Sketchup::Point3d] point2
    #
    # @since 2.0.0
    def initialize( *args )
      if args.size == 1
        @ray = args[0]
      elsif args.size == 2
        raise ArgumentError, 'First argument must be Point3d' unless args[0].is_a?( Geom::Point3d )
        if args[1].is_a?( Geom::Point3d )
          @ray = [ args[0], args[0].vector_to(args[1]) ]
        elsif args[1].is_a?( Geom::Vector3d )
          @ray = [ args[0], args[1] ]
        else
          raise ArgumentError, "Second argument must be Point3d or Vector3d.\n#{args[1].class.to_s}"
        end
      else
        raise ArgumentError, 'One or Two arguments'
      end
    end


    # Gets the origin of the ray.
    #
    # @return [Sketchup::Point3d]
    # @since 2.0.0
    def origin
      @ray[0]
    end

    # Sets the origin of the ray.
    #
    # @param [Sketchup::Point3d] point
    #
    # @return [Sketchup::Point3d]
    # @since 2.0.0
    def origin=(point)
      @ray[0] = point
    end


    # Gets the direction of the ray.
    #
    # @return [Sketchup::Vector3d]
    # @since 2.0.0
    def direction
      @ray[1]
    end

    # Sets the origin of the ray.
    #
    # @overload direction=(point)
    #   @param [Sketchup::Point3d] point
    # @overload direction=(vector)
    #   @param [Sketchup::Vector3d] vector
    #
    # @return [Sketchup::Vector3d]
    # @since 2.0.0
    def direction=(value)
      if value.is_a?( Geom::Point3d )
        @ray[1] = @ray[0].vector_to(value)
      elsif value.is_a?( Geom::Vector3d )
        @ray[1] = value
      else
        raise ArgumentError
      end
    end


    # @return [Array<Sketchup::Point3d, Sketchup::Vector3d>]
    # @since 2.0.0
    def to_a
      return @ray
    end

    # @return [String]
    # @since 2.0.0
    def to_s
      return "#{@ray[0]}, #{@ray[1]}"
    end


    # @return [String]
    # @since 2.0.0
    def inspect
      return "Ray(#{@ray[0].inspect}, #{@ray[1].inspect})"
    end


    # Test the ray and do not stop on hidden entities. Option to stop at ground
    # level.
    #
    # SketchUp 8.0M0 had a bug that made +Model.raytest+ unreliable. Advice users
    # to update.
    #
    # SketchUp prior to version 8.0M1 will not act reliably when one wants to hit
    # hidden entities. It will stop on hidden layers, but not on hidden entities.
    #
    # @param [Sketchup::Model] model
    # @param [Boolean] stop_at_ground
    #
    # @return [Array<Point3d, Array>, nil]
    # @since 2.0.0 - fixed in 2.5.0
    def test( model = Sketchup.active_model, stop_at_ground = false, wysiwyg = true )
      ground = [ORIGIN, Z_AXIS]
      origin, direction = @ray
      ray = @ray

      support_wysiwyg = TT::SketchUp.support?( TT::SketchUp::RAYTEST_WYSIWYG )

      while true

        # Shot ray. Make use of the wysiwyg in version Su8.0M1 and newer.
        if support_wysiwyg
          test_result = model.raytest( ray, wysiwyg )
        else
          test_result = model.raytest( ray )
        end

        # Check if the ray should stop at ground
        # Stop the ray at the ground if it misses any geometry.
        if test_result.nil?
          if stop_at_ground
            # Intersect ray with ground plane.
            pt = Geom.intersect_line_plane( @ray, ground )
            return nil if pt.nil? # Plane not hit.
            # Validate direction.
            v = origin.vector_to( pt )
            if v.valid? && v.samedirection?( direction )
              # Hit ground plane.
              return [ pt, [] ]
            else
              # Ground plane hit, but in the wrong direction. Means nothing was hit.
              return nil
            end
          else
            # Nothing hit.
            return nil
          end
        end

        # No need to process the ray further if it is SU8.0M1 or higher that runs
        # the raytest. These versions support control for visible/hidden tests.
        return test_result if support_wysiwyg

        # This point means that an older SketchUp version did the raytest and the
        # results may need further testing if only visible entities is supposed
        # to be hit.
        return test_result unless wysiwyg

        # SU8.0M1 added a new flag that control if raytest stops on hidden entities.
        # In earlier versions this was not availible. To work around this the ray
        # is recast if the ray stopped on a hidden entity.
        # Verify visibility
        point, path = test_result
        if path.all? { |e| e.visible? && e.layer.visible? }
          return test_result
        else
          ray = [ point, direction ]
        end

      end # while
    end

  end # class TT::Ray
end
