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

    # @param sketchup_model [Sketchup::Model] active model.
    def self.init_preferences(sketchup_model)
      # Init sqlite database
      db = Sqlite3::Database.new(SPECKLE_CONFIG_DB_PATH)

      # Select data
      data = db.exec("SELECT content FROM 'objects' WHERE hash = 'configDUI'").first.first

      # Parse string to hash
      data_hash = JSON.parse(data).to_h

      # Get current theme value
      dark_theme = data_hash['DarkTheme']

      speckle_dictionary = sketchup_model.attribute_dictionary('Speckle')

      if speckle_dictionary
        Immutable::Hash.new(
          {
            user: {
              dark_theme: dark_theme
            },
            model: {
              combine_faces_by_material: DICT_HANDLER.get_attribute(sketchup_model,
                                                                    :combine_faces_by_material, 'Speckle'),
              include_entity_attributes: DICT_HANDLER.get_attribute(sketchup_model,
                                                                    :include_entity_attributes, 'Speckle'),
              merge_coplanar_faces: DICT_HANDLER.get_attribute(sketchup_model,
                                                               :merge_coplanar_faces, 'Speckle')
            }
          }
        )
      else
        DICT_HANDLER.write_initial_model_data(sketchup_model, default_model_preferences)
        Immutable::Hash.new(
          {
            user: {
              dark_theme: dark_theme
            },
            model: default_model_preferences
          }
        )
      end
    end

    def self.default_model_preferences
      {
        combine_faces_by_material: true,
        include_entity_attributes: true,
        merge_coplanar_faces: true
      }
    end
  end
end
