# frozen_string_literal: true

# Define the method to export immutable structures to JSON. Default exporter would only export the name of the class as
# a string. In order to export it properly, we need to add `to_json` methods to the classes we want to serialize as JSON.
module SpeckleConnector3
  module Immutable
    class Vector
      # Convert the object to JSON
      # @return [String] json encoded string
      # @param args [Array] the arguments that will be passed to JSON.to_json method
      def to_json(*args)
        to_a.to_json(*args)
      end
    end
    class Hash
      # Convert the object to JSON
      # @return [String] json encoded string
      # @param args [Array] the arguments that will be passed to JSON.to_json method
      def to_json(*args)
        to_h.to_json(*args)
      end
    end
  end
end
