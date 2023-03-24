# frozen_string_literal: true

require_relative '../ext/sqlite3'
require_relative '../immutable/immutable'
require_relative '../constants/path_constants'
require_relative '../constants/pref_constants'
require_relative '../sketchup_model/dictionary/speckle_model_dictionary_handler'

module SpeckleConnector
  # Preferences that stored on config database and sketchup_model.
  module Preferences
    include Immutable::ImmutableUtils
    DICT_HANDLER = SketchupModel::Dictionary::SpeckleModelDictionaryHandler
    # rubocop:disable Layout/LineLength
    DEFAULT_CONFIG = "('configSketchup', '{\"dark_theme\":false, \"diffing\":false, \"register_speckle_entity\":false}');"
    # rubocop:enable Layout/LineLength
    DEFAULT_PREFERENCES = '{"dark_theme":false, "diffing":false, "register_speckle_entity": false}'

    # @param sketchup_model [Sketchup::Model] active model.
    def self.read_preferences(sketchup_model)
      db = Sqlite3::Database.new(SPECKLE_CONFIG_DB_PATH)
      user_preferences = validate_user_preferences(db)
      model_preferences = validate_model_preferences(sketchup_model)
      Immutable::Hash.new(
        {
          user: user_preferences,
          model: model_preferences
        }
      )
    end

    # Whether row data is complete with preference or not.
    # It is useful for backward compatibility, when we add new preferences it should be reset when user initialize it.
    def self.data_complete?(row_data)
      return false if row_data.empty?

      data = JSON.parse(row_data.first.first)
      return false if data['dark_theme'].nil? || data['diffing'].nil? || data['register_speckle_entity'].nil?

      true
    end

    # Validates current preferences. If there are incomplete data then this method resets it with default preferences.
    # @param database [Sqlite3::Database] database for queries.
    # rubocop:disable Metrics/MethodLength
    def self.validate_user_preferences(database)
      row_data = database.exec("SELECT content FROM 'objects' WHERE hash = 'configSketchup'")
      is_config_sketchup_exist = !row_data.empty?
      is_data_complete = data_complete?(row_data)
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

      # Select data
      row_data = database.exec("SELECT content FROM 'objects' WHERE hash = 'configSketchup'").first.first
      # Parse string to hash
      data_hash = JSON.parse(row_data).to_h
      # Get current theme value
      dark_theme = data_hash['dark_theme']
      diffing = data_hash['diffing']
      register_speckle_entity = data_hash['register_speckle_entity']

      {
        dark_theme: dark_theme,
        diffing: diffing,
        register_speckle_entity: register_speckle_entity
      }.freeze
    end
    # rubocop:enable Metrics/MethodLength

    # @param sketchup_model [Sketchup::Model] sketchup model to validate model preferences
    def self.validate_model_preferences(sketchup_model)
      speckle_dictionary = sketchup_model.attribute_dictionary('Speckle')
      if speckle_dictionary.nil?
        DICT_HANDLER.write_initial_model_data(sketchup_model, DEFAULT_MODEL_PREFERENCES)
        return DEFAULT_MODEL_PREFERENCES
      end

      DEFAULT_MODEL_PREFERENCES.collect do |pref_key, default_value|
        pref_value = DICT_HANDLER.get_attribute(
          sketchup_model,
          pref_key,
          'Speckle'
        )
        DICT_HANDLER.set_attribute(sketchup_model, pref_key, default_value, 'Speckle') if pref_value.nil?
        pref_value.nil? ? [pref_key, default_value] : [pref_key, pref_value]
      end.to_h
    end
  end
end
