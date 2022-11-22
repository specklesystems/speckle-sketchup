# frozen_string_literal: true

require 'json'

module SpeckleConnector
  module Typescript
    # Object to help convert object attributes to JSON and by checking types.
    class TypescriptObject
      # @param attributes [Hash{Symbol=>Object}] attributes are given as key value pairs
      def initialize(**attributes)
        @attributes = attributes
        check_attributes
      end

      # @return [String] the JSON representation of the object
      def to_json(*options)
        @attributes.to_json(*options)
      end

      def to_h(*options)
        JSON.parse(to_json(*options), { symbolize_names: true })
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity
      def check_attributes
        attribute_types.each do |key, class_or_classes|
          value = @attributes[key]
          case class_or_classes
          when Array
            is_class_correct = class_or_classes.any? do |klass|
              raise "#{klass} is not a class" unless klass.is_a? Class

              value.is_a? klass
            end
            raise "attribute #{key} is of class #{value.class} and not #{class_or_classes}" unless is_class_correct
          when Class
            raise ArgumentError, "#{class_or_classes} should be class" unless class_or_classes.is_a? Class

            unless value.is_a? class_or_classes
              raise ArgumentError,
                    "attribute #{key} is of class #{value.class} and not #{class_or_classes}"
            end
          else
            raise ArgumentError, "#{class_or_classes} should be class or array of classes"
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def attribute_types
        raise NotImplementedError, 'Implement in child class'
      end
    end
  end
end
