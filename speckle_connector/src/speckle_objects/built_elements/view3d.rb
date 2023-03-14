# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'
require_relative '../../speckle_objects/geometry/point'
require_relative '../../speckle_objects/geometry/vector'

module SpeckleConnector
  module SpeckleObjects
    module BuiltElements
      # View3d object represents scenes on Sketchup.
      class View3d < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_VIEW3D

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

        # @param obj [Hash] commit object.
        # @param sketchup_model [Sketchup::Model] active sketchup model.
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/CyclomaticComplexity
        def self.to_native(obj, sketchup_model)
          views = collect_views(obj)
          return if views.empty?

          views.each do |view|
            next unless view['speckle_type'] == 'Objects.BuiltElements.View:Objects.BuiltElements.View3D'

            name = view['name'] || view['id']
            next if sketchup_model.pages.any? { |page| page.name == name }

            origin = view['origin']
            target = view['target']
            lens = view['lens'] || 50
            origin = SpeckleObjects::Geometry::Point.to_native(origin['x'], origin['y'], origin['z'], origin['units'])
            target = SpeckleObjects::Geometry::Point.to_native(target['x'], target['y'], target['z'], target['units'])
            # Set camera position before creating scene on it.
            my_camera = Sketchup::Camera.new(origin, target, [0, 0, 1], !view['isOrthogonal'], lens)
            sketchup_model.active_view.camera = my_camera
            sketchup_model.pages.add(name)
            page = sketchup_model.pages[name]
            set_page_update_properties(page, view['update_properties']) if view['update_properties']
            set_rendering_options(page.rendering_options, view['rendering_options']) if view['rendering_options']
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity

        def self.collect_views(obj)
          views = []
          views += obj.filter_map do |_key, value|
            if value.is_a?(Array) &&
               value.any? { |v| v['speckle_type'] == OBJECTS_BUILTELEMENTS_VIEW3D }
              value
            end
          end
          views.flatten.select { |view| view['speckle_type'] == OBJECTS_BUILTELEMENTS_VIEW3D }
        end
      end
    end
  end
end
