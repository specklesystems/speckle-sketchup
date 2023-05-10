# frozen_string_literal: true

require_relative 'converter'
require_relative '../constants/type_constants'
require_relative '../speckle_objects/gis/polygon_element'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/other/block_definition'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/display_value'
require_relative '../speckle_objects/revit/revit_instance'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/mesh'
require_relative '../speckle_objects/built_elements/view3d'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module Converters
    # Converts sketchup entities to speckle objects.
    # rubocop:disable Metrics/ClassLength
    class ToNative < Converter
      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_accessor :speckle_state

      # @return [String] source application of received object that will be converted to native
      attr_reader :source_app

      def initialize(state, stream_id, stream_name, branch_name, source_app)
        super(state, stream_id)
        @stream_name = stream_name
        @branch_name = branch_name
        @source_app = source_app.downcase
      end

      # Module aliases
      GEOMETRY = SpeckleObjects::Geometry
      OTHER = SpeckleObjects::Other
      REVIT = SpeckleObjects::Revit
      BUILTELEMENTS = SpeckleObjects::BuiltElements
      GIS = SpeckleObjects::GIS

      # Class aliases
      POINT = GEOMETRY::Point
      LINE = GEOMETRY::Line
      MESH = GEOMETRY::Mesh
      BLOCK_DEFINITION = OTHER::BlockDefinition
      BLOCK_INSTANCE = OTHER::BlockInstance
      REVIT_INSTANCE = REVIT::Other::RevitInstance
      RENDER_MATERIAL = OTHER::RenderMaterial
      DISPLAY_VALUE = OTHER::DisplayValue
      VIEW3D = BUILTELEMENTS::View3d
      POLYGON_ELEMENT = GIS::PolygonElement

      BASE_OBJECT_PROPS = %w[applicationId id speckle_type totalChildrenCount].freeze
      CONVERTABLE_SPECKLE_TYPES = %w[
        Objects.Geometry.Line
        Objects.Geometry.Polyline
        Objects.Geometry.Mesh
        Objects.Geometry.Brep
        Objects.Other.BlockInstance
        Objects.Other.Revit.RevitInstance
        Objects.Other.BlockDefinition
        Objects.Other.RenderMaterial
        Objects.Other.Instance:Objects.Other.BlockInstance
        Objects.BuiltElements.View:Objects.BuiltElements.View3D
        Objects.GIS.PolygonElement
      ].freeze

      def from_revit
        @from_revit ||= source_app.include?('revit')
      end

      def from_sketchup
        @from_sketchup ||= source_app.include?('sketchup')
      end

      def from_qgis
        @from_qgis ||= source_app.include?('qgis')
      end

      # ReceiveObjects action call this method by giving everything that comes from server.
      # Upcoming object is a referencedObject of selected commit to receive.
      # UI is responsible currently to fetch objects from ObjectLoader module by calling getAndConstruct method.
      # @param obj [Object] speckle commit object.
      def receive_commit_object(obj)
        # First create layers on the sketchup before starting traversing
        # @Named Views are exception here. It does not mean a layer. But it is anti-pattern for now.
        layers_relation = obj['layers_relation']

        # Create layers and it's folders from layers relation on the model collection.
        SpeckleObjects::Relations::Layers.to_native(layers_relation, sketchup_model) if layers_relation && !from_revit

        # By default entities to fill is sketchup model's entities.
        @entities_to_fill = sketchup_model.entities

        # Navigate to branch entities if commit doesn't come from sketchup
        unless from_sketchup
          @branch_definition = branch_definition
          @entities_to_fill = @branch_definition.entities
        end

        traverse_commit_object(obj, @entities_to_fill)
        create_levels_from_section_planes
        check_hiding_layers_needed

        if !from_sketchup && !@is_update_commit
          instance = sketchup_model.entities.add_instance(@branch_definition, Geom::Transformation.new)
          BLOCK_INSTANCE.align_instance_axes(instance) if from_qgis
        end
        @state
      end

      def levels_layer
        @levels_layer ||= sketchup_model.layers.add('Levels')
      end

      def clear_levels
        instances = @entities_to_fill.grep(Sketchup::ComponentInstance)
        instances.each do |instance|
          speckle_type = instance.get_attribute(SPECKLE_BASE_OBJECT, 'speckle_type')
          next if speckle_type.nil?

          sketchup_model.definitions.remove(instance.definition) if speckle_type == OBJECTS_BUILTELEMENTS_REVIT_LEVEL
        end
      end

      # Create levels from section planes that already created for this commit object.
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def create_levels_from_section_planes
        clear_levels if @is_update_commit
        return unless from_revit

        section_planes = @entities_to_fill.grep(Sketchup::SectionPlane)
        bbox = @entities_to_fill.parent.bounds
        c_1 = bbox.corner(0)
        c_2 = bbox.corner(1)
        c_3 = bbox.corner(3)
        c_4 = bbox.corner(2)
        section_planes.each do |section_plane|
          level_name = "#{@definition_name}-#{section_plane.name}"
          definition = sketchup_model.definitions.add(level_name)
          instance = @entities_to_fill.add_instance(definition, Geom::Transformation.new)
          att = section_plane.attribute_dictionary(SPECKLE_BASE_OBJECT).to_h
          SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.set_hash(instance, att)
          elevation = section_plane.bounds.center.z
          c1_e = Geom::Point3d.new(c_1.x, c_1.y, elevation - LEVEL_SHIFT_VALUE)
          c2_e = Geom::Point3d.new(c_2.x, c_2.y, elevation - LEVEL_SHIFT_VALUE)
          c3_e = Geom::Point3d.new(c_3.x, c_3.y, elevation - LEVEL_SHIFT_VALUE)
          c4_e = Geom::Point3d.new(c_4.x, c_4.y, elevation - LEVEL_SHIFT_VALUE)
          cline_1 = definition.entities.add_cline(c1_e, c2_e)
          cline_2 = definition.entities.add_cline(c2_e, c3_e)
          cline_3 = definition.entities.add_cline(c3_e, c4_e)
          cline_4 = definition.entities.add_cline(c4_e, c1_e)
          text = definition.entities.add_text(" #{section_plane.name}", c1_e)
          [cline_1, cline_2, cline_3, cline_4, text, definition].each { |o| o.layer = levels_layer }
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # @return [Sketchup::ComponentDefinition] branch definition to fill objects in it.
      def branch_definition
        @definition_name = "#{@branch_name}-#{@stream_name}"
        definition = sketchup_model.definitions.find { |d| d.name == @definition_name }
        @is_update_commit = !definition.nil?
        definition = sketchup_model.definitions.add(@definition_name) if definition.nil?
        definition
      end

      def entities_to_fill(_obj)
        return sketchup_model.entities unless from_revit

        @definition_name = "#{@branch_name}-#{@stream_name}"
        definition = sketchup_model.definitions.find { |d| d.name == @definition_name }
        if definition.nil?
          definition = sketchup_model.definitions.add(@definition_name)
          sketchup_model.entities.add_instance(definition, Geom::Transformation.new)
        end
        definition
      end

      LAYERS_WILL_BE_HIDDEN = [
        'Rooms',
        'Mass',
        'Mass Floor',
        'Grid',
        'Shaft Openings'
      ].freeze

      def check_hiding_layers_needed
        return unless from_revit

        sketchup_model.layers.each do |layer|
          if LAYERS_WILL_BE_HIDDEN.any? { |layer_name| layer.display_name.include?(layer_name) }
            layer.visible = false
            sketchup_model.pages.each { |page| page.update(PAGE_USE_LAYER_VISIBILITY) }
          end
        end
      end

      # Conditions for converting speckle object to native sketchup entity:
      #  1- `obj` is a hash
      #  2- `obj` has a property as 'speckle_type'
      #  3- `obj` is a convertable 'speckle_type' which sketchup supports
      # @param obj [Object] candidate object to convert from speckle to sketchup.
      # @return [Boolean] whether object is convertable or not.
      def convertible_to_native?(obj)
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
      def traverse_commit_object(obj, entities)
        if convertible_to_native?(obj)
          @state = convert_to_native(@state, obj, entities)
        elsif obj.is_a?(Hash) && obj.key?('speckle_type')
          return if ignored_speckle_type?(obj)

          if obj['displayValue'].nil?
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']}. Continuing traversal.")
            props = obj.keys.filter_map { |key| key unless key.start_with?('_') }
            props.each do |prop|
              traverse_commit_object(obj[prop], entities)
            end
          else
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']} with displayValue.")
            @state = convert_to_native(@state, obj, entities)
          end
        elsif obj.is_a?(Hash)
          obj.each_value { |value| traverse_commit_object(value, entities) }
        elsif obj.is_a?(Array)
          obj.each { |value| traverse_commit_object(value, entities) }
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def speckle_object_to_native(obj)
        return DISPLAY_VALUE.method(:to_native) unless obj['displayValue'].nil?

        SPECKLE_OBJECT_TO_NATIVE[obj['speckle_type']]
      end

      SPECKLE_OBJECT_TO_NATIVE = {
        OBJECTS_GEOMETRY_LINE => LINE.method(:to_native),
        OBJECTS_GEOMETRY_POLYLINE => LINE.method(:to_native),
        OBJECTS_GEOMETRY_MESH => MESH.method(:to_native),
        OBJECTS_GEOMETRY_BREP => MESH.method(:to_native),
        OBJECTS_OTHER_BLOCKDEFINITION => BLOCK_DEFINITION.method(:to_native),
        OBJECTS_OTHER_BLOCKINSTANCE => BLOCK_INSTANCE.method(:to_native),
        OBJECTS_OTHER_BLOCKINSTANCE_FULL => BLOCK_INSTANCE.method(:to_native),
        OBJECTS_OTHER_REVIT_REVITINSTANCE => REVIT_INSTANCE.method(:to_native),
        OBJECTS_OTHER_RENDERMATERIAL => RENDER_MATERIAL.method(:to_native),
        OBJECTS_BUILTELEMENTS_VIEW3D => VIEW3D.method(:to_native),
        OBJECTS_GIS_POLYGONELEMENT => POLYGON_ELEMENT.method(:to_native)
      }.freeze

      # @param state [States::State] state of the speckle application
      def convert_to_native(state, obj, entities = sketchup_model.entities)
        # store this method as parameter to re-call it inner callstack
        convert_to_native = method(:convert_to_native)
        # Get 'to_native' method to convert upcoming speckle object to native sketchup entity
        to_native_method = speckle_object_to_native(obj)
        # Call 'to_native' method by passing this method itself to handle nested 'to_native' conversions.
        # It returns updated state and converted entities.
        state, converted_entities = to_native_method.call(state, obj, entities, &convert_to_native)
        if from_revit
          # Create levels as section planes if they exists
          create_levels(state, obj)
          # Create layers from category of object and place object in it
          create_layers_from_categories(state, obj, converted_entities)
        end
        # Create speckle entities from sketchup entities to achieve continuous traversal.
        convert_to_speckle_entities(state, obj, converted_entities)
      rescue StandardError => e
        puts("Failed to convert #{obj['speckle_type']} (id: #{obj['id']})")
        puts(e)
        return state
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def create_layers_from_categories(state, speckle_object, entities)
        return state if speckle_object['category'].nil?

        layer = sketchup_model.layers.find { |l| l.display_name == speckle_object['category'] }
        unless layer.nil?
          entities.each { |entity| entity.layer = layer if entity.respond_to?(:layer) } if layer
          return state
        end

        layer = sketchup_model.layers.add(speckle_object['category'])
        unless layer.nil?
          entities.each { |entity| entity.layer = layer if entity.respond_to?(:layer) } if layer
          state
        end
        state
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # @param state [States::State] state of the speckle application
      def create_levels(state, speckle_object)
        level = speckle_object['level']
        return state if level.nil?
        return state unless level['speckle_type'].include?('Objects.BuiltElements.Level')

        level_name = level['name'] || level['id']
        is_exist = @entities_to_fill.grep(Sketchup::SectionPlane).any? { |sp| sp.name == level_name }
        return state if is_exist

        elevation = SpeckleObjects::Geometry.length_to_native(level['elevation'], level['units'])

        section_plane = @entities_to_fill.add_section_plane([0, 0, elevation + LEVEL_SHIFT_VALUE], [0, 0, -1])
        section_plane.name = level_name
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.write_initial_base_data(
          section_plane, level['applicationId'], level['id'], level['speckle_type'], [], @stream_id
        )
        state
      end

      # @param state [States::State] state of the application
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def convert_to_speckle_entities(state, speckle_object, entities)
        return state if entities.empty?

        speckle_id = speckle_object['id']
        application_id = speckle_object['applicationId']
        speckle_type = speckle_object['speckle_type']
        children = speckle_object['__closure'].nil? ? [] : speckle_object['__closure']
        speckle_state = state.speckle_state
        entities.each do |entity|
          next if entity.is_a?(Sketchup::Material) || entity.is_a?(Sketchup::Page)
          next if (entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)) &&
                  !state.user_state.user_preferences[:register_speckle_entity]

          ent = SpeckleEntities::SpeckleEntity.new(entity, speckle_id, application_id, speckle_type, children,
                                                   [stream_id])
          ent.write_initial_base_data
          speckle_state = speckle_state.with_speckle_entity(ent)
        end
        state.with_speckle_state(speckle_state)
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
    end
    # rubocop:enable Metrics/ClassLength
  end
end
