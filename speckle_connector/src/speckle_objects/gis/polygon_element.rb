# frozen_string_literal: true

require_relative '../base'
require_relative '../other/transform'
require_relative '../other/block_definition'
require_relative '../other/block_instance'
require_relative '../../constants/type_constants'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module GIS
      # BoundingBox object definition for Speckle.
      class PolygonElement < Base
        SPECKLE_TYPE = OBJECTS_GIS_POLYGONELEMENT

        def self.get_definition_name(obj, attributes)
          return obj['name'] unless obj['name'].nil?

          return attributes['name'] unless attributes['name'].nil?

          return "def::#{obj['id']}"
        end

        def self.get_qgis_attributes(obj)
          attributes = obj['attributes'].to_h
          speckle_properties = %w[id speckle_type totalChildrenCount units applicationId]
          speckle_properties.each { |key| attributes.delete(key) }
          attributes
        end

        # Handles polygon element differently from display value.
        def self.to_native(state, obj, layer, entities, &convert_to_native)
          attributes = get_qgis_attributes(obj)
          obj = collect_definition_geometries(obj)
          obj['name'] = get_definition_name(obj, attributes)

          state, _definitions = Other::BlockDefinition.to_native(
            state,
            obj,
            layer,
            entities,
            &convert_to_native
          )

          definition = state.sketchup_state.sketchup_model
                            .definitions[Other::BlockDefinition.get_definition_name(obj)]

          Other::BlockInstance.find_and_erase_existing_instance(definition, obj['id'], obj['applicationId'])
          t_arr = obj['transform']
          transform = t_arr.nil? ? Geom::Transformation.new : Other::Transform.to_native(t_arr, obj['units'])
          instance = entities.add_instance(definition, transform)
          instance.name = obj['name'] unless obj['name'].nil?
          SketchupModel::Dictionary::DictionaryHandler.set_hash(instance, attributes, 'qgis')
          SketchupModel::Dictionary::DictionaryHandler.set_hash(definition, attributes, 'qgis')
          # Align instance axes that created from display value. (without any transform)
          Other::BlockInstance.align_instance_axes(instance)
          return state, [instance, definition]
        end

        def self.collect_definition_geometries(obj)
          geometries = []

          # FIXME: This type check needed because of QGIS. It can send geometries both way, object or array..
          #  This is something need to be fixed by QGIS.
          if obj['geometry'].is_a?(Array)
            obj['geometry'].each do |geometry|
              display_value = geometry['displayValue']

              geometries += display_value
            end
          else
            geometries += obj['geometry']['displayValue']
          end

          geometries.each do |geo|
            if geo['speckle_type'] && geo['speckle_type'] == OBJECTS_GEOMETRY_MESH
              geo['sketchup_attributes'] = { 'is_soften' => false }
            end
          end

          obj['geometry'] = geometries
          obj
        end
      end
    end
  end
end
