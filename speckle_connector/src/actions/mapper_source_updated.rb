# frozen_string_literal: true

require_relative 'action'
require_relative '../mapper/mapper_source'
require_relative '../speckle_objects/built_elements/revit/revit_element_type'

module SpeckleConnector
  module Actions
    # Action to update mapper source.
    class MapperSourceUpdated < Action
      def initialize(base, stream_id, commit_id)
        super()
        @base = base
        @stream_id = stream_id
        @commit_id = commit_id
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        levels = convert_levels(state, @base['@Levels'])
        types = convert_types(@base['@Types'])
        mapper_source = Mapper::MapperSource.new(@stream_id, @commit_id, levels, types)
        new_speckle_state = state.speckle_state.with_mapper_source(mapper_source)
        state = state.with_speckle_state(new_speckle_state)

        state.with_add_queue('mapperSourceUpdated', @stream_id, [
                               { is_string: false, val: levels.to_json },
                               { is_string: false, val: types.to_json }
                             ])
      end

      def convert_types(types)
        types.collect do |type, type_elements|
          next if type_elements.nil? || !type_elements.is_a?(Array) || type == '__closure'

          type = type[1..-1] if type[0] == '@'
          elements = type_elements.map do |type_element|
            SpeckleObjects::BuiltElements::Revit::RevitElementType.to_native(type_element)
          end
          [type, elements]
        end.compact.to_h
      end

      def convert_levels(state, levels)
        levels.collect do |level|
          SpeckleObjects::BuiltElements::Level.to_native(state, level)
        end
      end
    end
  end
end
