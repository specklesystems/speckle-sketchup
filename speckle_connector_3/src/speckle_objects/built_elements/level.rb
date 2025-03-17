# frozen_string_literal: true

require_relative '../base'
require_relative '../other/render_material'
require_relative '../geometry/line'
require_relative '../geometry/length'
require_relative '../geometry/polyline'
require_relative '../../constants/type_constants'
require_relative '../../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module BuiltElements
      # Level object.
      class Level < Base
        SPECKLE_TYPE = OBJECTS_BUILTELEMENTS_REVIT_LEVEL

        def initialize(name:, elevation:, units:, element_id:, application_id: nil, id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            application_id: application_id,
            id: id
          )
          self[:name] = name
          self[:elevation] = elevation
          self[:units] = units
          self[:elementId] = element_id
          self[:referenceOnly] = true
          self[:createView] = false
        end

        # @param state [States::State] state of the application.
        def self.to_native(state, speckle_level, stream_id)
          sketchup_model = state.sketchup_state.sketchup_model
          levels_layer = sketchup_model.layers.layers.find { |layer| layer.display_name == 'Levels' }
          levels_layer = sketchup_model.layers.add('Levels') if levels_layer.nil?

          name = speckle_level['name']
          elevation = speckle_level['elevation']
          units = speckle_level['units']
          element_id = speckle_level['elementId']
          application_id = speckle_level['applicationId']
          id = speckle_level['id']

          skp_elevation = Geometry.length_to_native(elevation, units)

          definition_name = "#{name}-#{application_id}"
          definition = sketchup_model.definitions.find { |definition| definition.name == definition_name }
          definition.entities.clear! unless definition.nil?
          definition = sketchup_model.definitions.add(definition_name) if definition.nil?
          instance = sketchup_model.entities.add_instance(definition, Geom::Transformation.new)
          instance.locked = true
          SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.write_initial_base_data(
            instance, application_id, id, SPECKLE_TYPE, [], stream_id
          )
          SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.set_attribute(instance, :name, name)

          SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.write_initial_base_data(
            definition, application_id, id, SPECKLE_TYPE, [], stream_id
          )
          SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.set_attribute(definition, :name, name)

          c1_e = Geom::Point3d.new(0, 10.m, skp_elevation)
          c2_e = Geom::Point3d.new(0, 0, skp_elevation)
          c3_e = Geom::Point3d.new(10.m, 0, skp_elevation)
          cline_1 = definition.entities.add_cline(c1_e, c2_e)
          cline_2 = definition.entities.add_cline(c2_e, c3_e)
          text = definition.entities.add_text(" #{name}", c1_e)
          [cline_1, cline_2, text, definition, instance].each { |o| o.layer = levels_layer }

          Level.new(
            name: name,
            elevation: elevation,
            units: units,
            element_id: element_id,
            application_id: application_id,
            id: speckle_level['id']
          )
        end
      end
    end
  end
end
