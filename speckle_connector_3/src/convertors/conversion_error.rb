# frozen_string_literal: true

module SpeckleConnector3
  module Converters
    class ConverterError < StandardError
      # @return [UiData::Report::ConversionStatus::WARNING] level of the error.
      attr_reader :level

      # @param message [String] message for error.
      # @param level [UiData::Report::ConversionStatus::WARNING] level of the error.
      def initialize(message = "An error occurred on conversion", level)
        @level = level
        super(message) # Calls the parent class's initialize method with the message
      end
    end
  end
end
