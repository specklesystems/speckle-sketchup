# frozen_string_literal: true

require_relative '../ext/sqlite3'
require_relative '../immutable/immutable'
require_relative '../constants/path_constants'
require_relative '../sketchup_model/dictionary/speckle_model_dictionary_handler'

module SpeckleConnector
  # Preferences that stored on config database and sketchup_model.
  # rubocop:disable Metrics/ModuleLength
  module Preferences
    include Immutable::ImmutableUtils
    DICT_HANDLER = SketchupModel::Dictionary::SpeckleModelDictionaryHandler
    DEFAULT_CONFIG = "('configSketchup', '{\"dark_theme\":false, \"diffing\":false}');"
    DEFAULT_PREFERENCES = '{"dark_theme":false, "diffing":false}'

    # @param sketchup_model [Sketchup::Model] active model.
    # rubocop:disable Metrics/MethodLength
    def self.read_preferences(sketchup_model)
      db = Sqlite3::Database.new(SPECKLE_CONFIG_DB_PATH)
      validate_preferences(db)

      # Select data
      row_data = db.exec("SELECT content FROM 'objects' WHERE hash = 'configSketchup'").first.first
      # Parse string to hash
      data_hash = JSON.parse(row_data).to_h
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

    # Whether row data is complete with preference or not.
    # It is useful for backward compatibility, when we add new preferences it should be reset when user initialize it.
    def self.data_complete?(row_data)
      return false if row_data.empty?

      data = JSON.parse(row_data.first.first)
      return false if data['dark_theme'].nil? || data['diffing'].nil?

      true
    end

    # Validates current preferences. If there are incomplete data then this method resets it with default preferences.
    # @param database [Sqlite3::Database] database for queries.
    def self.validate_preferences(database)
      row_data = database.exec("SELECT content FROM 'objects' WHERE hash = 'configSketchup'")
      is_config_sketchup_exist = !row_data.empty?
      is_data_complete = data_complete?(row_data)
      # rubocop:disable Style/GuardClause
      if !is_config_sketchup_exist || !is_data_complete
        if is_config_sketchup_exist
          unless is_data_complete
            # Update table with default preferences
            database.exec("UPDATE 'objects' SET content = '#{DEFAULT_PREFERENCES}' WHERE hash = 'configSketchup'")
          end
        else
          # Insert configSketchup completely to objects.
          database.exec("INSERT INTO 'objects' VALUES #{DEFAULT_CONFIG}")
        end
      end
      # rubocop:enable Style/GuardClause
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
