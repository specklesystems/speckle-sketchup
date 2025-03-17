# frozen_string_literal: true

require_relative 'action'
require_relative 'add_material'
require_relative '../constants/mat_constants'

module SpeckleConnector3
  module Actions
    # Action to initialize materials
    class InitializeMaterials < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        new_state = recreate_material(state, DEFAULT_NAMES[MAT_ADD], DEFAULT_COLORS[MAT_ADD], MAT_ADD)
        new_state = recreate_material(new_state, DEFAULT_NAMES[MAT_EDIT], DEFAULT_COLORS[MAT_EDIT], MAT_EDIT)
        recreate_material(new_state, DEFAULT_NAMES[MAT_REMOVE], DEFAULT_COLORS[MAT_REMOVE], MAT_REMOVE)
      end

      def self.recreate_material(state, name, color, id, alpha: nil)
        Actions::AddMaterial.update_state(
          state,
          material_name: name,
          color: color,
          material_id: id,
          alpha: alpha
        )
      end
    end
  end
end
