# frozen_string_literal: true

require_relative 'render_material'
require_relative 'transform'
require_relative 'block_definition'
require_relative '../../immutable/immutable'
require_relative '../../ext/immutable_ruby/hash'
require_relative '../base'
require_relative '../geometry/bounding_box'
require_relative '../../sketchup_model/dictionary/base_dictionary_handler'

module SpeckleConnector
  module SpeckleObjects
    module Other
      # DisplayValue object definition for Speckle that represents as BlockInstance in Sketchup.
      class DisplayValue
        def self.get_definition_name(def_obj)
          family = def_obj['family']
          type = def_obj['type']
          category = def_obj['category']
          element_id = def_obj['elementId']

          return format_naming_convention([family, type, category, element_id]) unless element_id.nil?

          return "def::#{def_obj['applicationId']}" unless def_obj['applicationId'].nil?

          return "def::#{def_obj['id']}"
        end

        def self.format_naming_convention(entries)
          name = ''
          entries.each_with_index do |entry, index|
            next if entry.nil?

            name += if index == entries.length - 1
                      entry.to_s
                    else
                      "#{entry}-"
                    end
          end
          name
        end

        # Creates a component definition and instance from a speckle object with a display value
        # @param state [States::State] state of the application.
        def self.to_native(state, obj, layer, entities, &convert_to_native)
          # Switch displayValue with geometry
          obj = collect_definition_geometries(obj)
          obj['name'] = get_definition_name(obj)

          state, _definitions = BlockDefinition.to_native(
            state,
            obj,
            layer,
            entities,
            &convert_to_native
          )

          definition = state.sketchup_state.sketchup_model.definitions[BlockDefinition.get_definition_name(obj)]

          BlockInstance.find_and_erase_existing_instance(definition, obj['id'], obj['applicationId'])
          t_arr = obj['transform']
          transform = t_arr.nil? ? Geom::Transformation.new : OTHER::Transform.to_native(t_arr, obj['units'])
          instance = entities.add_instance(definition, transform)
          instance.name = obj['name'] unless obj['name'].nil?
          instance.layer = layer unless layer.nil?
          # Align instance axes that created from display value. (without any transform)
          # BlockInstance.align_instance_axes(instance)
          return state, [instance, definition]
        end

        def self.collect_definition_geometries(obj)
          obj['geometry'] = obj['displayValue']

          if !obj['elements'].nil? && obj['elements'].is_a?(Array)
            obj['elements'].each do |element|
              # Mullions is a special case here, they are extracted as base object with @displayValue from revit..
              if element['@displayValue'].nil?
                obj['geometry'].append(element)
              else
                obj['geometry'] += element['@displayValue']
              end
            end
          end
          obj
        end
      end
    end
  end
end
