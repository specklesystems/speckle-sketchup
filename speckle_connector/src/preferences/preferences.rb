# frozen_string_literal: true

require_relative '../ext/sqlite3'
require_relative '../immutable/immutable'
require_relative '../constants/path_constants'
require_relative '../sketchup_model/dictionary/speckle_model_dictionary_handler'

module SpeckleConnector
  # Preferences that stored on config database and sketchup_model.
  module Preferences
    include Immutable::ImmutableUtils
    DICT_HANDLER = SketchupModel::Dictionary::SpeckleModelDictionaryHandler
    DEFAULT_CONFIG = "('configSketchup', '{\"dark_theme\":false, \"diffing\":false}');"
    DEFAULT_PREFERENCES = "{\"dark_theme\":false, \"diffing\":false}"

    # @param sketchup_model [Sketchup::Model] active model.
    # rubocop:disable Metrics/MethodLength
    def self.init_preferences(sketchup_model)
      # Init sqlite database
      db = Sqlite3::Database.new(SPECKLE_CONFIG_DB_PATH)

      data = db.exec("SELECT content FROM 'objects' WHERE hash = 'configSketchup'")
      is_data_empty = data.empty?
      is_data_incomplete = !is_data_empty && !JSON.parse(data.first.first).to_h.length != 2

      # Check configSketchup key is valid or not, otherwise init with default settings
      if is_data_empty || is_data_incomplete
        db.exec("INSERT INTO 'objects' VALUES #{DEFAULT_CONFIG}") if is_data_empty
        if is_data_incomplete
          db.exec("UPDATE 'objects' SET content = '#{DEFAULT_PREFERENCES}' WHERE hash = 'configSketchup'")
        end
      end

      # Select data
      data = db.exec("SELECT content FROM 'objects' WHERE hash = 'configSketchup'").first.first

      # Parse string to hash
      data_hash = JSON.parse(data).to_h

      # Get current theme value
      dark_theme = data_hash['dark_theme']
      diffing = data_hash['diffing']

      speckle_dictionary = sketchup_model.attribute_dictionary('Speckle')

      if speckle_dictionary
        Immutable::Hash.new(
          {
            user: {
              dark_theme: dark_theme,
              diffing: diffing
            },
            model: {
              combine_faces_by_material: DICT_HANDLER.get_attribute(
                sketchup_model,
                :combine_faces_by_material,
                'Speckle'
              ),
              include_entity_attributes: DICT_HANDLER.get_attribute(
                sketchup_model,
                :include_entity_attributes,
                'Speckle'
              ),
              include_face_entity_attributes: DICT_HANDLER.get_attribute(
                sketchup_model,
                :include_face_entity_attributes,
                'Speckle'
              ),
              include_edge_entity_attributes: DICT_HANDLER.get_attribute(
                sketchup_model,
                :include_edge_entity_attributes,
                'Speckle'
              ),
              include_group_entity_attributes: DICT_HANDLER.get_attribute(
                sketchup_model,
                :include_group_entity_attributes,
                'Speckle'
              ),
              include_component_entity_attributes: DICT_HANDLER.get_attribute(
                sketchup_model,
                :include_component_entity_attributes,
                'Speckle'
              ),
              merge_coplanar_faces: DICT_HANDLER.get_attribute(
                sketchup_model,
                :merge_coplanar_faces,
                'Speckle'
              )
            }
          }
        )
      else
        DICT_HANDLER.write_initial_model_data(sketchup_model, default_model_preferences)
        Immutable::Hash.new(
          {
            user: {
              dark_theme: dark_theme,
              diffing: diffing
            },
            model: default_model_preferences
          }
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

    def self.default_model_preferences
      {
        combine_faces_by_material: true,
        include_entity_attributes: true,
        include_face_entity_attributes: true,
        include_edge_entity_attributes: true,
        include_group_entity_attributes: true,
        include_component_entity_attributes: true,
        merge_coplanar_faces: true
      }
    end
  end
end
