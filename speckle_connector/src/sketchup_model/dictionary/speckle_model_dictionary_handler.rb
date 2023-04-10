# frozen_string_literal: true

require_relative 'base_dictionary_handler'
require_relative '../../constants/dict_constants'
require_relative '../../constants/type_constants'

module SpeckleConnector
  module SketchupModel
    module Dictionary
      # Dictionary handler of the speckle model.
      class SpeckleModelDictionaryHandler < BaseDictionaryHandler
        DICTIONARY_NAME = 'Speckle'
        # Writes initial data while speckle entity is creating first time.
        # @param sketchup_model [Sketchup::Model] Sketchup model to write data into it's attribute dictionary.
        def self.write_initial_model_data(sketchup_model, default_preferences)
          set_hash(sketchup_model, default_preferences, DICTIONARY_NAME)
        end
      end
    end
  end
end
