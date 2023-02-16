# frozen_string_literal: true

require_relative '../immutable/immutable'
require_relative '../convertors/units'
require_relative '../sketchup_model/dictionary/speckle_entity_dictionary_handler'

module SpeckleConnector
  module SpeckleEntities
    module SpeckleEntityStatus
      # Speckle Entity created first time with {Sketchup::Entity} before sent to server.
      UP_TO_DATE = 0
      # {Sketchup::Entity} that corresponds to Speckle Entity is edited after created by user.
      EDITED = 1
      # {Sketchup::Entity} that corresponds to Speckle Entity is removed.
      REMOVED = 2
    end
  end
end
