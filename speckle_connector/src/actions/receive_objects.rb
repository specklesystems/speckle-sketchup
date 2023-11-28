# frozen_string_literal: true

require_relative 'action'
require_relative '../convertors/units'
require_relative '../convertors/to_native'
require_relative '../convertors/clean_up'

module SpeckleConnector
  module Actions
    # Action to receive objects from Speckle Server.
    class ReceiveObjects < Action
      # rubocop:disable Metrics/ParameterLists
      def initialize(stream_id, base, stream_name, branch_name, branch_id, source_app)
        super()
        @stream_id = stream_id
        @base = base
        @stream_name = stream_name
        @branch_name = branch_name
        @branch_id = branch_id
        @source_app = source_app
      end
      # rubocop:enable Metrics/ParameterLists

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def update_state(state)
        converter = Converters::ToNative.new(state, @stream_id, @stream_name, @branch_name, @source_app)
        # Have side effects on the sketchup model. It effects directly on the entities by adding new objects.
        start_time = Time.now.to_f
        state.sketchup_state.sketchup_model.start_operation('Receive Speckle Objects', true)
        state = converter.receive_commit_object(@base)
        if state.user_state.model_preferences[:merge_coplanar_faces]
          Converters::CleanUp.merge_coplanar_faces(converter.converted_faces)
        end
        state.sketchup_state.sketchup_model.commit_operation
        elapsed_time = (Time.now.to_f - start_time).round(3)
        puts "==== Converting to Native executed in #{elapsed_time} sec ===="
        puts "==== Source application is #{@source_app}. ===="
        state.with_add_queue('finishedReceiveInSketchup', @stream_id, [])
      end
    end
  end
end
