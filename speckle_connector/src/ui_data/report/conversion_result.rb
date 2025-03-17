# frozen_string_literal: true

module SpeckleConnector
  module UiData
    module Report
      module ConversionStatus
        SUCCESS = 1
        INFO = 2
        WARNING = 3
        ERROR = 4
      end

      # Exception to convert UI data.
      class ConversionException < Hash
        # @return [String] Message to show
        attr_reader :message

        # @return [String] stack trace of the exception
        attr_reader :stack_trace

        # @param error [Exception] error to convert data
        def initialize(error)
          super()
          @message = error.message
          @stack_trace = error.backtrace.join("\n")
          self[:message] = @message
          self[:stackTrace] = @stack_trace
        end
      end

      # Data to send UI for each conversion.
      class ConversionResult < Hash

        # @return [ConversionStatus] status of the conversion
        attr_reader :status

        # @return [String] For receive conversion reports, this is the id of the speckle object.
        #  For send, it's the host app object id.
        attr_reader :source_id

        # @return [String] For receive conversion reports, this is the type of the speckle object.
        #  For send, it's the host app object type.
        attr_reader :source_type

        # @return [String] For receive conversion reports, this is the id of the host app object.
        #  For send, it's the speckle object id.
        attr_reader :result_id

        # @return [String] For receive conversion reports, this is the type of the host app object.
        #  For send, it's the speckle object type.
        attr_reader :result_type

        # @return [ConversionError, NilClass] the exception data if any.
        attr_reader :error

        def initialize(status, source_id, source_type, result_id, result_type, exception = nil)
          super()
          @status = status
          @source_id = source_id
          @source_type = source_type
          @result_id = result_id
          @result_type = result_type
          @error = ConversionException.new(exception) if exception
          self[:status] = @status
          self[:sourceId] = @source_id
          self[:sourceType] = @source_type
          self[:resultId] = @result_id
          self[:resultType] = @result_type
          self[:error] = @error
        end
      end
    end
  end
end
