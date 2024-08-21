# frozen_string_literal: true

require_relative 'layer'
require_relative '../base'

module SpeckleConnector3
  module SpeckleObjects
    module Relations
      # Sketchup layers (tag) tree relation. The difference between Layer is, this is the top object that holds
      # properties for all layers or folders, i.e. active layer.
      class Layers < Base
        SPECKLE_TYPE = 'Speckle.Core.Models.Collection'

        def initialize(active:, layers:, application_id: nil)
          super(
            speckle_type: SPECKLE_TYPE,
            application_id: nil,
            id: nil
          )
          self[:active_layer] = active
          self[:elements] = layers
        end

        # Extract relations from commit obj to create layers in advance.
        # By doing this, also checks layers will be created as flat list or nested structure according to source app.
        # @param commit_obj [Hash] commit object to extract layer relations.
        # @param source_app [String] source application to decide layer creation strategy.
        # Currently for
        # - Revit: we don't create layers in advance because we create layers according to categories.
        # - SketchUp: we create layers in advance as nested.
        # - Rhino: we create layers in advance as flat list with it's full path.
        def self.extract_relations(commit_obj, source_app)
          return nil unless commit_obj['speckle_type'] == SPECKLE_CORE_MODELS_COLLECTION

          elements = element_to_relation(commit_obj['@elements'] || commit_obj['elements'], source_app, [])

          Layers.new(
            active: commit_obj['active_layer'],
            layers: elements
          )
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def self.element_to_relation(elements, source_app, parent_layers)
          elements.collect do |element|
            next unless element['speckle_type'] == SPECKLE_CORE_MODELS_LAYER_COLLECTION || element['speckle_type'] == SPECKLE_CORE_MODELS_COLLECTION

            layers_tree = parent_layers.dup.append(element['name'])
            full_path = ''
            parent_layers.each { |parent| full_path += "#{parent}::" }
            full_path += element['name']
            # Add this info to commit object to check later layer_collection conversion
            element['full_path'] = full_path if source_app.include?('rhino')

            is_folder = (element['@elements'] || element['elements']).any? { |e| e['speckle_type'] == SPECKLE_CORE_MODELS_LAYER_COLLECTION }
            # color = element['color'] || element['displayStyle']['color'] # FIXME: with colors implementation
            Layer.new(
              name: element['name'], visible: element['visible'], is_folder: is_folder,
              color: nil,
              full_path: full_path,
              layers_and_folders: element_to_relation(element['@elements'] || element['elements'], source_app, layers_tree),
              application_id: element['applicationId'], id: element['id']
            )
          end.compact
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        # @param sketchup_model [Sketchup::Model]
        # @param model_card [Cards::Card] model card
        def self.to_native(obj, color_proxies, sketchup_model, source_app, model_card)
          layers_relation = extract_relations(obj, source_app)
          return if layers_relation.nil?
          model_id = model_card.model_id
          project_id = model_card.project_id

          folder_name = "#{model_card.project_name}-#{model_card.model_name}"
          existing_folder = sketchup_model.layers.folders.find { |f| f.display_name == folder_name }
          sketchup_model.layers.remove_folder(existing_folder) if existing_folder
          model_folder = sketchup_model.layers.add_folder("#{model_card.project_name}-#{model_card.model_name}")

          is_flat = source_app.include?('rhino') # flat by meaning -> adds :: for children

          # FIXME: UPDATE BEHAVIOR: !!! NOT SURE it is a good idea !!!
          SpeckleObjects::Relations::Layer.deep_clean(sketchup_model, project_id, model_id)

          if is_flat
            SpeckleObjects::Relations::Layer.to_native_flat_layers(layers_relation, color_proxies, model_folder, sketchup_model, project_id, model_id)
          else
            SpeckleObjects::Relations::Layer.to_native_layer_folder(layers_relation, color_proxies, model_folder, sketchup_model, project_id, model_id)
          end

          active_layer = sketchup_model.layers.to_a.find { |layer| layer.display_name == layers_relation['active_layer'] }
          sketchup_model.active_layer = active_layer unless active_layer.nil?
        end

        def self.from_model(sketchup_model)
          # init with headless layers
          headless_layers = sketchup_model.layers.layers.collect do |layer|
            SpeckleObjects::Relations::Layer.from_layer(layer)
          end

          folders = sketchup_model.layers.folders.collect do |folder|
            SpeckleObjects::Relations::Layer.from_folder(folder)
          end

          Layers.new(
            active: sketchup_model.active_layer.display_name,
            layers: headless_layers + folders
          )
        end
      end
    end
  end
end
