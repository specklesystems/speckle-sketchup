# frozen_string_literal: true

require_relative 'action'
require_relative '../mapper/category/revit_category'
require_relative '../mapper/category/revit_family_category'

module SpeckleConnector3
  module Actions
    # Collects mapper selection info.
    class MapperInitialized < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, _data)
        init_parameters = {
          categories: Mapper::Category::RevitCategory.to_a,
          familyCategories: Mapper::Category::RevitFamilyCategory.to_a
        }.freeze
        state.with_mapper_init_queue(init_parameters)
      end
    end
  end
end
