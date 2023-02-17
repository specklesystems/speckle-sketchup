# frozen_string_literal: true

require_relative '../base'
require_relative '../../speckle_objects/geometry/point'
require_relative '../../speckle_objects/geometry/vector'

module SpeckleConnector
  module SpeckleObjects
    module BuiltElements
      # View3d object represents scenes on Sketchup.
      class View3d < Base
        SPECKLE_TYPE = 'Objects.BuiltElements.View:Objects.BuiltElements.View3D'

        # @param name [String] name of the scene
        # @param origin [SpeckleObjects::Geometry::Point] origin (eye) of the view.
        # @param target [SpeckleObjects::Geometry::Point] target of the view.
        # @param direction [SpeckleObjects::Geometry::Vector] direction of the view from eye to target.
        # @param up_direction [SpeckleObjects::Geometry::Vector] up direction of the view.
        # @param is_perspective [Boolean] whether view is perspective or not.
        # @param lens [Boolean] fov value of the view camera.
        # @param units [String] units of the camera.
        # @param application_id [String] application_id of the view.
        # @param update_properties [Hash{Symbol=>boolean}] properties of the view.
        # @param rendering_options [Hash{Symbol=>boolean}] rendering options of the view.
        # rubocop:disable Metrics/ParameterLists
        def initialize(name, origin, target, direction, up_direction,
                       is_perspective, lens, units, application_id, update_properties, rendering_options)
          super(
            speckle_type: SPECKLE_TYPE,
            total_children_count: 0,
            application_id: application_id,
            id: nil
          )
          self[:name] = name
          self[:origin] = origin
          self[:target] = target
          self[:forwardDirection] = direction
          self[:upDirection] = up_direction
          self[:isOrthogonal] = !is_perspective
          self[:lens] = lens
          self[:units] = units
          self[:update_properties] = update_properties
          self[:rendering_options] = rendering_options
        end
        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end
