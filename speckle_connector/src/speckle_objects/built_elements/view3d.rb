# frozen_string_literal: true

require_relative '../base'
require_relative '../../constants/type_constants'
require_relative '../../speckle_objects/geometry/length'
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
        # @param lens [Numeric] focal length value of the view camera.
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

        # Collects scenes as views from sketchup model.
        # @param sketchup_model [Sketchup::Model] sketchup model to collect views from pages.
        # @param units [String] units of the model.
        def self.from_model(sketchup_model, units)
          sketchup_model.pages.collect { |page| from_page(page, units) }
        end

        # @param page [Sketchup::Page] page to convert speckle view.
        def self.from_page(page, units)
          cam = page.camera
          origin = get_camera_origin(cam, units)
          target = get_camera_target(cam, units)
          direction = get_camera_direction(cam, units)
          update_properties = get_scene_update_properties(page)
          rendering_options = SpeckleObjects::Other::RenderingOptions.to_speckle(page.rendering_options)
          View3d.new(
            page.name, origin, target, direction, SpeckleObjects::Geometry::Vector.new(0, 0, 1, units),
            cam.perspective?, cam.perspective? ? cam.focal_length : 35, units, page.name,
            update_properties, rendering_options
          )
        end

        # @param state [States::State] state of the speckle app.
        # @param obj [Hash] commit object.
        def self.to_native(state, view, _layer, _entities, &_convert_to_native)
          sketchup_model = state.sketchup_state.sketchup_model
          return state, [] unless view['speckle_type'] == 'Objects.BuiltElements.View:Objects.BuiltElements.View3D'

          name = view['name'] || view['id']
          return state, [] if sketchup_model.pages.any? { |page| page.name == name }

          camera = create_camera(view)
          sketchup_model.active_view.camera = camera
          sketchup_model.pages.add(name)
          page = sketchup_model.pages[name]
          set_page_update_properties(page, view['update_properties']) if view['update_properties']
          set_rendering_options(page.rendering_options, view['rendering_options']) if view['rendering_options']
          return state, [page]
        end

        def self.create_camera(view)
          origin = view['origin']
          target = view['target']
          focal_length = view['lens'] || 35
          origin = SpeckleObjects::Geometry::Point.to_native(origin['x'], origin['y'], origin['z'], origin['units'])
          target = SpeckleObjects::Geometry::Point.to_native(target['x'], target['y'], target['z'], target['units'])
          view_direction = (origin - target).normalize
          up = view_direction.parallel?([0, 0, 1]) ? [0, 1, 0] : [0, 0, 1]
          # Set camera position before creating scene on it.
          is_perspective = !view['isOrthogonal']
          camera = Sketchup::Camera.new(origin, target, up, is_perspective)
          camera.focal_length = focal_length if is_perspective
          camera.height = (origin - target).length * 2 unless is_perspective
          camera
        end

        # @param page [Sketchup::Page] scene to update -update properties-
        def self.set_page_update_properties(page, update_properties)
          update_properties.each do |prop, value|
            page.instance_variable_set(:"@#{prop}", value)
          end
        end

        # @param rendering_options [Sketchup::RenderingOptions] rendering options of scene (page)
        def self.set_rendering_options(rendering_options, speckle_rendering_options)
          speckle_rendering_options.each do |prop, value|
            next if rendering_options[prop].nil?

            rendering_options[prop] = if value.is_a?(Hash)
                                        SpeckleObjects::Other::Color.to_native(value)
                                      else
                                        value
                                      end
          end
        end

        # Get scene properties
        # @param page [Sketchup::Page] page on sketchup.
        def self.get_scene_update_properties(page)
          {
            use_axes: page.use_axes?,
            use_camera: page.use_camera?,
            use_hidden_geometry: page.use_hidden_geometry?,
            use_hidden_layers: page.use_hidden_layers?,
            use_hidden_objects: page.use_hidden_objects?,
            use_rendering_options: page.use_rendering_options?,
            use_section_planes: page.use_section_planes?,
            use_shadow_info: page.use_shadow_info?,
            use_style: page.use_style?
          }
        end

        def self.get_camera_direction(camera, units)
          SpeckleObjects::Geometry::Vector.new(
            SpeckleObjects::Geometry.length_to_speckle(camera.direction[0], units),
            SpeckleObjects::Geometry.length_to_speckle(camera.direction[1], units),
            SpeckleObjects::Geometry.length_to_speckle(camera.direction[2], units),
            units
          )
        end

        def self.get_camera_target(camera, units)
          SpeckleObjects::Geometry::Point.new(
            SpeckleObjects::Geometry.length_to_speckle(camera.target[0], units),
            SpeckleObjects::Geometry.length_to_speckle(camera.target[1], units),
            SpeckleObjects::Geometry.length_to_speckle(camera.target[2], units),
            units
          )
        end

        def self.get_camera_origin(camera, units)
          SpeckleObjects::Geometry::Point.new(
            SpeckleObjects::Geometry.length_to_speckle(camera.eye[0], units),
            SpeckleObjects::Geometry.length_to_speckle(camera.eye[1], units),
            SpeckleObjects::Geometry.length_to_speckle(camera.eye[2], units),
            units
          )
        end
      end
    end
  end
end
