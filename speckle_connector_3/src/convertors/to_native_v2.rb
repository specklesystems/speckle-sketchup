# frozen_string_literal: true

require_relative 'converter_v2'
require_relative '../constants/type_constants'
require_relative '../speckle_entities/speckle_entity'
require_relative '../speckle_objects/gis/polygon_element'
require_relative '../speckle_objects/gis/line_element'
require_relative '../speckle_objects/other/transform'
require_relative '../speckle_objects/other/render_material'
require_relative '../speckle_objects/other/block_definition'
require_relative '../speckle_objects/other/block_instance'
require_relative '../speckle_objects/other/display_value'
require_relative '../speckle_objects/revit/revit_instance'
require_relative '../speckle_objects/geometry/point'
require_relative '../speckle_objects/geometry/line'
require_relative '../speckle_objects/geometry/polycurve'
require_relative '../speckle_objects/geometry/arc'
require_relative '../speckle_objects/geometry/circle'
require_relative '../speckle_objects/geometry/mesh'
require_relative '../speckle_objects/built_elements/view3d'
require_relative '../speckle_objects/built_elements/network'
require_relative '../speckle_objects/speckle/core/models/collection'
require_relative '../speckle_objects/speckle/core/models/gis_layer_collection'
require_relative '../speckle_objects/instance_definition_proxy'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'
require_relative '../ui_data/report/conversion_result'
require_relative '../convertors/conversion_error'

module SpeckleConnector3
  module Converters
    # Converts sketchup entities to speckle objects.
    # rubocop:disable Metrics/ClassLength
    class ToNativeV2 < ConverterV2
      # @return [States::SpeckleState] the current speckle state of the {States::State}
      attr_accessor :speckle_state

      # @return [String] source application of received object that will be converted to native
      attr_reader :source_app

      attr_reader :converted_faces

      attr_reader :converted_entities

      attr_reader :conversion_results

      attr_reader :project_model_name

      # @return [Array<SpeckleObjects::InstanceDefinitionProxy>]
      attr_reader :root_definition_proxies

      # @return [Array<SpeckleObjects::RenderMaterialProxy>]
      attr_accessor :root_render_material_proxies

      # @param definition_proxies [Array<SpeckleObjects::InstanceDefinitionProxy>]
      # @param render_material_proxies [Array<SpeckleObjects::RenderMaterialProxy>]
      # @param model_card [SpeckleConnector3::Cards::ReceiveCard]
      def initialize(state, definition_proxies, render_material_proxies, source_app, model_card)
        super(state, model_card)
        @root_definition_proxies = definition_proxies
        @root_render_material_proxies = render_material_proxies
        @definition_proxies = {}
        @source_app = source_app.downcase
        @converted_faces = []
        @converted_entities = []
        @conversion_results = []
        @created_definitions = {}
        @project_model_name = "#{model_card.project_name}-#{model_card.model_name}"
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
      POLYCURVE = GEOMETRY::Polycurve
      ARC = GEOMETRY::Arc
      CIRCLE = GEOMETRY::Circle
      MESH = GEOMETRY::Mesh
      BLOCK_DEFINITION = OTHER::BlockDefinition
      BLOCK_INSTANCE = OTHER::BlockInstance
      REVIT_INSTANCE = REVIT::Other::RevitInstance
      REVIT_WALL = BUILTELEMENTS::RevitWall
      RENDER_MATERIAL = OTHER::RenderMaterial
      DISPLAY_VALUE = OTHER::DisplayValue
      VIEW3D = BUILTELEMENTS::View3d
      POLYGON_ELEMENT = GIS::PolygonElement
      LINE_ELEMENT = GIS::LineElement
      COLLECTION = SpeckleObjects::Speckle::Core::Models::Collection
      LAYER_COLLECTION = SpeckleObjects::Speckle::Core::Models::LayerCollection
      GIS_LAYER_COLLECTION = SpeckleObjects::Speckle::Core::Models::GisLayerCollection

      BASE_OBJECT_PROPS = %w[applicationId id speckle_type].freeze
      CONVERTABLE_SPECKLE_TYPES = %w[
        Objects.Geometry.Line
        Objects.Geometry.Polyline
        Objects.Geometry.Polycurve
        Objects.Geometry.Arc
        Objects.Geometry.Circle
        Objects.Geometry.Mesh
        Objects.Geometry.Brep
        Objects.Other.BlockInstance
        Objects.Other.Revit.RevitInstance
        Objects.Other.BlockDefinition
        Objects.Other.RenderMaterial
        Objects.Other.Instance:Objects.Other.BlockInstance
        Objects.BuiltElements.View:Objects.BuiltElements.View3D
        Objects.BuiltElements.Wall:Objects.BuiltElements.Revit.RevitWall
        Objects.BuiltElements.Network
        Objects.GIS.PolygonElement
        Objects.GIS.LineElement
        Speckle.Core.Models.Collections.Collection
        Speckle.Core.Models.Collections.Collection:Speckle.Core.Models.Collections.Layer
        Speckle.Core.Models.Collections.Collection:Objects.GIS.RasterLayer
        Speckle.Core.Models.Collections.Collection:Objects.GIS.VectorLayer
      ].freeze

      def from_revit
        @from_revit ||= source_app.include?('revit')
      end

      def from_rhino
        @from_rhino ||= source_app.include?('rhino')
      end

      def from_sketchup
        @from_sketchup ||= source_app.include?('sketchup')
      end

      def from_qgis
        @from_qgis ||= source_app.include?('qgis')
      end

      def create_render_materials
        return if root_render_material_proxies.nil?

        converted_render_material_proxies = []
        root_render_material_proxies.each do |proxy|
          material = SpeckleObjects::Other::RenderMaterial.to_native_from_proxy(sketchup_model, proxy["value"])
          render_material_proxy = SpeckleObjects::RenderMaterialProxy.new(material, proxy["value"], proxy["objects"])
          converted_render_material_proxies.append(render_material_proxy)
        end
        @root_render_material_proxies = converted_render_material_proxies
      end

      def create_definition_proxies
        root_definition_proxies.each do |proxy|
          next if proxy['name'].nil?

          definition_name = proxy['name']
          definition = state.sketchup_state.sketchup_model.definitions.add(definition_name)
          definition.behavior.always_face_camera = proxy['alwaysFaceCamera'] if proxy['alwaysFaceCamera']
          @definition_proxies[proxy['applicationId']] = SpeckleObjects::InstanceDefinitionProxy.new(
            definition,
            proxy['objects'],
            proxy['maxDepth'].nil? ? 0 : proxy['maxDepth']
          )
        end
      end

      # ReceiveObjects action call this method by giving everything that comes from server.
      # Upcoming object is a referencedObject of selected commit to receive.
      # UI is responsible currently to fetch objects from ObjectLoader module by calling getAndConstruct method.
      # @param obj [Object] speckle commit object.
      def receive_commit_object(obj)
        # TODO
        create_definition_proxies
        create_render_materials

        #unless from_revit
        #  # Create layers and it's folders from layers relation on the model collection.
        #  SpeckleObjects::Relations::Layers.to_native(obj, obj["colorProxies"], sketchup_model, source_app, model_card)
        #end

        SpeckleObjects::Relations::Layers.to_native(obj, obj["colorProxies"], sketchup_model, source_app, model_card)

        # By default entities to fill is sketchup model's entities.
        @entities_to_fill = sketchup_model.entities

        # Navigate to branch entities if commit doesn't come from sketchup
        unless from_sketchup
          @project_model_definition = project_model_definition
          @entities_to_fill = @project_model_definition.entities
        end

        default_commit_layer = sketchup_model.layers.layers.find { |layer| layer.display_name == '@Untagged' }

        traverse_commit_object(obj, default_commit_layer, @entities_to_fill)
        create_levels_from_section_planes
        check_hiding_layers_needed
        try_create_instance
        @state
      end

      # Creating instance from @project_model_definition only available for non-sketchup commits since we wrap commits
      # under instance.
      # There is also another use case that maybe definition is exist in file but user might be deleted it before.
      # If this is the case we can add instance by checking number of instances.
      # rubocop:disable Style/GuardClause
      def try_create_instance
        if !from_sketchup && (!@is_update_commit || @project_model_definition.instances.empty?)
          if project_model_folder
            SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.set_hash(
              project_model_layer, {
              project_id: model_card.project_id,
              model_id: model_card.model_id
            }
            )
            project_model_folder.add_layer(project_model_layer)
          end
          instance = sketchup_model.entities.add_instance(@project_model_definition, Geom::Transformation.new)
          instance.layer = project_model_layer if project_model_layer
          @converted_entities.append(instance)
          BLOCK_INSTANCE.align_instance_axes(instance) if from_qgis
        end
      end
      # rubocop:enable Style/GuardClause

      # @return [Sketchup::LayerFolder]
      def project_model_folder
        project_model_folder = sketchup_model.layers.folders.find { |f| f.display_name == @project_model_name }
        unless project_model_folder
          project_model_folder = sketchup_model.layers.add_folder(@project_model_name)
        end
        @project_model_folder = project_model_folder
      end

      def project_model_layer
        @project_model_layer ||= sketchup_model.layers.add_layer(@project_model_name)
      end

      def levels_layer
        @levels_layer ||= sketchup_model.layers.add("#{@project_model_name}-Levels")
        model_folder = sketchup_model.layers.folders.find { |f| f.display_name == @project_model_name }
        if model_folder
          model_folder.add_layer(@levels_layer)
        end
        @levels_layer
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
          level_name = "#{@project_model_name}-#{section_plane.name}"
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
      def project_model_definition
        definition = sketchup_model.definitions.find { |d| d.name == @project_model_name }
        @is_update_commit = !definition.nil?
        definition = sketchup_model.definitions.add(@project_model_name) if definition.nil?
        definition
      end

      def entities_to_fill(_obj)
        return sketchup_model.entities unless from_revit

        definition = sketchup_model.definitions.find { |d| d.name == @project_model_name }
        if definition.nil?
          definition = sketchup_model.definitions.add(@project_model_name)
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
      def traverse_commit_object(obj, layer, entities)
        if convertible_to_native?(obj)
          @state, _converted_entities = convert_to_native(@state, obj, layer, entities)
        elsif obj.is_a?(Hash) && obj.key?('speckle_type')
          return if ignored_speckle_type?(obj)

          if obj['displayValue'].nil?
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']}. Continuing traversal.")
            props = obj.keys.filter_map { |key| key unless key.start_with?('_') }
            props.each do |prop|
              traverse_commit_object(obj[prop], layer, entities)
            end
          else
            # puts(">>> Found #{obj['speckle_type']}: #{obj['id']} with displayValue.")
            @state, _converted_entities = convert_to_native(@state, obj, layer, entities)
          end
        elsif obj.is_a?(Hash)
          obj.each_value { |value| traverse_commit_object(value, layer, entities) }
        elsif obj.is_a?(Array)
          obj.each { |value| traverse_commit_object(value, layer, entities) }
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def speckle_object_to_native(obj)
        return DISPLAY_VALUE.method(:to_native) unless obj['displayValue'].nil? && obj['@displayValue'].nil?

        SPECKLE_OBJECT_TO_NATIVE[obj['speckle_type']]
      end

      SPECKLE_OBJECT_TO_NATIVE = {
        SPECKLE_CORE_MODELS_INSTANCES_INSTANCE_PROXY => SpeckleObjects::InstanceProxy.method(:to_native),
        OBJECTS_GEOMETRY_LINE => LINE.method(:to_native),
        OBJECTS_GEOMETRY_POLYLINE => LINE.method(:to_native),
        OBJECTS_GEOMETRY_POLYCURVE => POLYCURVE.method(:to_native),
        OBJECTS_GEOMETRY_AUTOCAD_POLYCURVE => POLYCURVE.method(:to_native),
        OBJECTS_GEOMETRY_ARC => ARC.method(:to_native),
        OBJECTS_GEOMETRY_CIRCLE => CIRCLE.method(:to_native),
        OBJECTS_GEOMETRY_MESH => MESH.method(:to_native),
        OBJECTS_GEOMETRY_BREP => MESH.method(:to_native),
        OBJECTS_OTHER_BLOCKDEFINITION => BLOCK_DEFINITION.method(:to_native),
        OBJECTS_OTHER_BLOCKINSTANCE => BLOCK_INSTANCE.method(:to_native),
        OBJECTS_OTHER_BLOCKINSTANCE_FULL => BLOCK_INSTANCE.method(:to_native),
        OBJECTS_OTHER_REVIT_REVITINSTANCE => REVIT_INSTANCE.method(:to_native),
        OBJECTS_OTHER_RENDERMATERIAL => RENDER_MATERIAL.method(:to_native),
        OBJECTS_BUILTELEMENTS_VIEW3D => VIEW3D.method(:to_native),
        OBJECTS_BUILTELEMENTS_REVIT_WALL => REVIT_WALL.method(:to_native),
        OBJECTS_BUILTELEMENTS_REVIT_DIRECTSHAPE => BUILTELEMENTS::Revit::DirectShape.method(:to_native),
        OBJECTS_BUILTELEMENTS_NETWORK => BUILTELEMENTS::Network.method(:to_native),
        OBJECTS_GIS_POLYGONELEMENT => POLYGON_ELEMENT.method(:to_native),
        OBJECTS_GIS_LINEELEMENT => LINE_ELEMENT.method(:to_native),
        SPECKLE_CORE_MODELS_COLLECTION => COLLECTION.method(:to_native),
        SPECKLE_CORE_MODELS_LAYER_COLLECTION => LAYER_COLLECTION.method(:to_native),
        SPECKLE_CORE_MODELS_COLLECTION_RASTER_LAYER => GIS_LAYER_COLLECTION.method(:to_native),
        SPECKLE_CORE_MODELS_COLLECTION_VECTOR_LAYER => GIS_LAYER_COLLECTION.method(:to_native)
      }.freeze

      def entities_to_bake(obj, entities)
        entities_to_bake = entities
        object_id = obj['applicationId'].to_s # TODO: CONVERTER_V2: faces have integer application id..!!?
        @definition_proxies.each do |_id, proxy|
          if proxy.object_ids.include?(object_id)
            entities_to_bake = proxy.definition.entities
            break
          end
        end
        entities_to_bake
      end

      # @param state [States::State] state of the speckle application
      def convert_to_native(state, obj, layer, entities = sketchup_model.entities)
        entities = entities_to_bake(obj, entities)
        # store this method as parameter to re-call it inner callstack
        convert_to_native = method(:convert_to_native)
        # Get 'to_native' method to convert upcoming speckle object to native sketchup entity
        to_native_method = speckle_object_to_native(obj)
        # Call 'to_native' method by passing this method itself to handle nested 'to_native' conversions.
        # It returns updated state and converted entities.
        state, converted_entities = if obj['speckle_type'] == SPECKLE_CORE_MODELS_INSTANCES_INSTANCE_PROXY
                                      to_native_method.call(state, obj, layer, entities, @definition_proxies, &convert_to_native)
                                    else
                                      to_native_method.call(state, obj, layer, entities, &convert_to_native)
                                    end
        # state, converted_entities = to_native_method.call(state, obj, layer, entities, &convert_to_native)
        @converted_entities += converted_entities
        converted_entities.each do |e|
          material_to_assign = find_material_from_proxies(obj['applicationId'].to_s)
          e.material = material_to_assign if material_to_assign
          e.back_material = material_to_assign if material_to_assign
          if from_sketchup && e.is_a?(Sketchup::Face)
            back_material_to_assign = find_material_from_proxies("#{obj['applicationId'].to_s}_back")
            e.back_material = back_material_to_assign if back_material_to_assign
          end
        end
        faces = converted_entities.select { |e| e.is_a?(Sketchup::Face) }
        @converted_faces += faces if faces.any?
        if from_revit
          # Create levels as section planes if they exists
          create_levels(state, obj)
          # Create layers from category of object and place object in it
          # create_layers_from_categories(state, obj, converted_entities)
        end
        # Create speckle entities from sketchup entities to achieve continuous traversal.

        converted_entities.each do |converted|
          @conversion_results.push(UiData::Report::ConversionResult.new(UiData::Report::ConversionStatus::SUCCESS,
                                                                        obj['id'],
                                                                        obj['speckle_type'],
                                                                        converted.persistent_id.to_s,
                                                                        converted.class, ""))

        end
        SpeckleEntities::SpeckleEntity.from_speckle_object(state, obj, converted_entities, model_card.project_id)
      rescue Converters::ConverterError => e
        message = "#{obj['speckle_type']} (id: #{obj['id']}) failed to convert."
        puts(message)
        puts(e)
        @conversion_results.push(UiData::Report::ConversionResult.new(e.level,
                                                                      obj['id'],
                                                                      obj['speckle_type'],
                                                                      nil,
                                                                      nil,
                                                                      message,
                                                                      e))
        return state, []
      rescue StandardError => e
        message = "#{obj['speckle_type']} (id: #{obj['id']}) failed to convert."
        puts(message)
        puts(e)
        @conversion_results.push(UiData::Report::ConversionResult.new(UiData::Report::ConversionStatus::ERROR,
                                                                      obj['id'],
                                                                      obj['speckle_type'],
                                                                      nil,
                                                                      nil,
                                                                      message,
                                                                      e))
        return state, []
      end

      def find_material_from_proxies(id)
        return nil if root_render_material_proxies.nil?

        root_render_material_proxies.each do |proxy|
          if proxy.object_ids.include?(id)
            return proxy.sketchup_material
          end
        end
        nil
      end

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
        section_plane.layer = levels_layer
        SketchupModel::Dictionary::SpeckleEntityDictionaryHandler.write_initial_base_data(
          section_plane, level['applicationId'], level['id'], level['speckle_type'], [], model_card.project_id
        )
        state
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
