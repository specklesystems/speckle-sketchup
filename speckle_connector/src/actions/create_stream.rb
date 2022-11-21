# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative '../actions/save_stream'
require_relative '../actions/queue_send'
require_relative '../convertors/converter'

module SpeckleConnector
  module Actions
    # Create stream.
    class CreateStream < Action
      def initialize(stream_name: nil)
        super()
        @stream_name = stream_name
      end

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      # rubocop:disable Metrics/MethodLength
      def update_state(state)
        puts 'send to speckle'
        acct = Accounts.default_account
        if acct.nil?
          puts 'No local account found. Please refer to speckle.guide for more information.'
          return state
        end
        sketchup_model = state.sketchup_state.sketchup_model
        path = sketchup_model.path
        if @stream_name.nil?
          @stream_name = path ? File.basename(path, '.*') : 'Untitled SketchUp Model'
        end
        query = 'mutation streamCreate($stream: StreamCreateInput!) {streamCreate(stream: $stream)}'
        vars = { stream: { name: @stream_name, description: 'Stream created from SketchUp' } }
        request = Sketchup::Http::Request.new("#{acct['serverInfo']['url']}/graphql", Sketchup::Http::POST)
        request.headers = { 'Authorization' => "Bearer #{acct['token']}", 'Content-Type' => 'application/json' }
        request.body = { query: query, variables: vars }.to_json
        to_convert = if sketchup_model.selection.count > 0
                       sketchup_model.selection
                     else
                       sketchup_model.entities
                     end
        state = evaluate_request(sketchup_model, request, state, to_convert)
        Actions::LoadSavedStreams.update_state(state, {})
      end
      # rubocop:enable Metrics/MethodLength

      private

      def evaluate_request(sketchup_model, request, state, to_convert)
        converter = Converters::Converter.new(sketchup_model)

        request.start do |_req, res|
          res_data = JSON.parse(res.body)['data']
          raise(StandardError) unless res_data

          stream_id = res_data['streamCreate']
          state = Actions::SaveStream.new(stream_id).update_state(state)
          converted = to_convert.map { |entity| converter.convert_to_speckle(entity) }
          state = Actions::QueueSend.new(stream_id, converted).update_state(state)
        end
        state
      end
    end
  end
end
