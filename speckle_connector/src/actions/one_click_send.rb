# frozen_string_literal: true

require_relative 'action'
require_relative '../accounts/accounts'
require_relative '../actions/create_stream'
require_relative '../actions/queue_send'

module SpeckleConnector
  module Actions
    # Sends to speckle.
    class OneClickSend < Action
      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state)
        puts 'send to speckle'
        default_account = Accounts.default_account
        if default_account.nil?
          puts 'No local account found. Please refer to speckle.guide for more information.'
          return state
        end
        sketchup_model = state.sketchup_state.sketchup_model
        to_convert = sketchup_model.selection.count > 0 ? sketchup_model.selection : sketchup_model.entities
        first_saved_stream = first_saved_stream(sketchup_model)
        action = if first_saved_stream.nil?
                   Actions::CreateStream.new
                 else
                   Actions::QueueSend.new(first_saved_stream, convert_to_speckle(sketchup_model, to_convert))
                 end

        action.update_state(state)
      end

      def self.first_saved_stream(model)
        (saved_streams = model.attribute_dictionary('speckle', true)['streams']) or []
        saved_streams.nil? || saved_streams.empty? ? nil : saved_streams[0]
      end

      def self.convert_to_speckle(sketchup_model, to_convert)
        converter = Converters::ConverterSketchup.new(sketchup_model)
        to_convert.map { |entity| converter.convert_to_speckle(entity) }
      end
    end
  end
end
