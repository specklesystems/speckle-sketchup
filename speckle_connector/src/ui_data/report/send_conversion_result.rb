# frozen_string_literal: true

module SpeckleConnector
  module UiData
    module Report
      class SendConversionResult < Hash
        attr_reader :result_id

        attr_reader :result_app_id

        # @return [SpeckleObjects::Base, NilClass]
        attr_reader :result

        attr_reader :error

        attr_reader :error_message

        attr_reader :target

        attr_reader :target_type

        attr_reader :is_successful

        def initialize(target, target_type, target_id, result = nil, error = nil)
          super()
          @target = target
          @target_type = target_type
          @target_id = target_id
          @result = result
          @result_id = result[:id] if result
          @result_app_id = result[:applicationId] if result
          @error = error
          @error_message = error.message if error
          @is_successful = !result.nil?
          self[:target] = @target
          self[:targetType] = @target_type
          self[:targetId] = @target_id
          self[:error] = @error if error
          self[:errorMessage] = @error_message if error
          self[:isSuccessful] = @is_successful
        end

        def self.success(target, target_type, target_id, result)
          SendConversionResult(target, target_type, target_id, result)
        end

        def self.fail(target, target_type, target_id, error)
          SendConversionResult(target, target_type, target_id, nil, error)
        end
      end
    end
  end
end
