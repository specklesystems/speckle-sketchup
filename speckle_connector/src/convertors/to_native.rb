# frozen_string_literal: true

require_relative 'converter'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/mesh'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    class ToNative < Converter
      # Module aliases
      GEOMETRY = SpeckleObjects::Geometry
      OTHER = SpeckleObjects::Other

      # Class aliases
      POINT = GEOMETRY::Point
      LINE = GEOMETRY::Line
      MESH = GEOMETRY::Mesh
      BLOCK_DEFINITION = OTHER::BlockDefinition
      BLOCK_INSTANCE = OTHER::BlockInstance

      BASE_OBJECT_PROPS = %w[applicationId id speckle_type totalChildrenCount].freeze
      CONVERTABLE_SPECKLE_TYPES = %w[
        Objects.Geometry.Line
        Objects.Geometry.Polyline
        Objects.Geometry.Mesh
        Objects.Geometry.Brep
        Objects.Other.BlockInstance
        Objects.Other.BlockDefinition
        Objects.Other.RenderMaterial
      ].freeze

      def can_convert_to_native(obj)
        return false unless obj.is_a?(Hash) && obj.key?('speckle_type')

        CONVERTABLE_SPECKLE_TYPES.include?(obj['speckle_type'])
      end

      def ignored_speckle_type?(obj)
        ['Objects.BuiltElements.Revit.Parameter'].include?(obj['speckle_type'])
      end

      # Traversal method to create Sketchup objects from upcoming base object.
      # @param obj [Hash, Array] object might be source base object or it's sub objects, because this method is a
      #   self-caller method means that call itself according to conditions inside of it.
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def traverse_commit_object(obj)
        if can_convert_to_native(obj)
          convert_to_native(obj)
        elsif obj.is_a?(Hash) && obj.key?('speckle_type')
          return if ignored_speckle_type?(obj)

          if obj['displayValue'].nil?
            puts(">>> Found #{obj['speckle_type']}: #{obj['id']}. Continuing traversal.")
            props = obj.keys.filter_map { |key| key unless key.start_with?('_') }
            props.each { |prop| traverse_commit_object(obj[prop]) }
          else
            puts(">>> Found #{obj['speckle_type']}: #{obj['id']} with displayValue.")
            convert_to_native(obj)
          end
        elsif obj.is_a?(Hash)
          obj.each_value { |value| traverse_commit_object(value) }
        elsif obj.is_a?(Array)
          obj.each { |value| traverse_commit_object(value) }
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # rubocop:disable Metrics/CyclomaticComplexity
      def convert_to_native(obj, entities = sketchup_model.entities)
        return display_value_to_native_component(obj, entities) unless obj['displayValue'].nil?

        convert = method(:convert_to_native)
        case obj['speckle_type']
        when 'Objects.Geometry.Line', 'Objects.Geometry.Polyline' then LINE.to_native(obj, entities)
        when 'Objects.Other.BlockInstance' then BLOCK_INSTANCE.to_native(sketchup_model, obj, entities, &convert)
        when 'Objects.Other.BlockDefinition' then BLOCK_DEFINITION.to_native(sketchup_model, obj, entities, &convert)
        when 'Objects.Geometry.Mesh' then MESH.to_native(sketchup_model, obj, entities)
        when 'Objects.Geometry.Brep' then MESH.to_native(sketchup_model, obj['displayValue'], entities)
        end
      rescue StandardError => e
        puts("Failed to convert #{obj['speckle_type']} (id: #{obj['id']})")
        puts(e)
        nil
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # creates a component definition and instance from a speckle object with a display value
      def display_value_to_native_component(obj, entities)
        obj_id = obj['applicationId'].to_s.empty? ? obj['id'] : obj['applicationId']
        definition = BLOCK_DEFINITION.to_native(
          sketchup_model,
          obj['displayValue'],
          "def::#{obj_id}",
          &method(:convert_to_native)
        )

        find_and_erase_existing_instance(definition, obj_id)
        t_arr = obj['transform']
        transform = t_arr.nil? ? Geom::Transformation.new : OTHER::Transform.to_native(t_arr, units)
        instance = entities.add_instance(definition, transform)
        instance.name = obj_id
        instance
      end

      # takes a component definition and finds and erases the first instance with the matching name
      # (and optionally the applicationId)
      def find_and_erase_existing_instance(definition, name, app_id = '')
        definition.instances.find { |ins| ins.name == name || ins.guid == app_id }&.erase!
      end
    end
  end
end
