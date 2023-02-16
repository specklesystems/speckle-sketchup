# frozen_string_literal: true

require_relative 'dictionary_handler'
require_relative '../../constants/dict_constants'
require_relative '../../constants/type_constants'

module SpeckleConnector
  module SketchupModel
    module Dictionary
      # Dictionary handler of the speckle entity.
      class SpeckleEntityDictionaryHandler < DictionaryHandler
        # Writes initial data while speckle entity is creating first time.
        # @param sketchup_entity [Sketchup::Entity] Sketchup entity to write data into it's attribute dictionary.
        # rubocop:disable Metrics/ParameterLists
        def self.write_initial_base_data(sketchup_entity, application_id, id, speckle_type, children_count, stream_id)
          initial_dict_data = {
            # Add here more if you want to write here initial data
            SPECKLE_ID => id,
            APPLICATION_ID => application_id,
            SPECKLE_TYPE => speckle_type,
            TOTAL_CHILDREN_COUNT => children_count,
            VALID_STREAM_IDS => [stream_id],
            INVALID_STREAM_IDS => []
          }
          set_hash(sketchup_entity, initial_dict_data)
        end
        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end
