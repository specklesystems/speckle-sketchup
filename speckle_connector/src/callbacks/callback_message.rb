# frozen_string_literal: true

module SpeckleConnector
  module Callbacks
    # Helper class to serialize messages to send dialog.
    class CallbackMessage
      # @param callback_name [String] name of the callback command
      # @param stream_id [String] id of the stream
      # @param parameters [Array<String>] parameters of the callback method call
      def self.serialize(callback_name, stream_id, parameters)
        if parameters.any?
          serialize_with_parameters(callback_name, stream_id, parameters)
        else
          serialize_without_parameters(callback_name, stream_id)
        end
      end

      # @param callback_name [String] name of the callback command
      # @param stream_id [String] id of the stream
      # @param parameters [Array<Object>] parameters of the callback method call
      def self.serialize_with_parameters(callback_name, stream_id, parameters)
        message = "#{callback_name}('#{stream_id}'"
        parameters.each { |par| message += par[:is_string] ? ",'#{par[:val]}'" : ",#{par[:val]}" }
        message += ')'
        message
      end

      # @param callback_name [String] name of the callback command
      # @param stream_id [String] id of the stream
      def self.serialize_without_parameters(callback_name, stream_id)
        if %w[setSavedStreams loadAccounts].include?(callback_name)
          "#{callback_name}(#{stream_id})"
        else
          "#{callback_name}('#{stream_id}')"
        end
      end
    end
  end
end
