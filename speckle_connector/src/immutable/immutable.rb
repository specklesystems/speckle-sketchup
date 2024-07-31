# frozen_string_literal: true

module SpeckleConnector3
  module Immutable
    # Mixin module with utilities for immutable objects
    module ImmutableUtils
      # Create a copy of the object with some of its instance variables changed
      # @param kw_args [{Symbol=>Object}] names and values for the instance variables that need to be changed
      # @return [Object] the same kind of object with some of the instance variables changed
      def with(**kw_args)
        return self if instance_variables_equal(**kw_args)

        new_object = dup
        kw_args.each do |var_name, value|
          new_object.instance_variable_set(var_name, value)
        end
        new_object
      end

      # Check if the given arguments are the same objects as the corresponding instance variables
      # @param kw_args [{Symbol=>Object}] names and values for the instance variables to be compared
      # @return [Boolean] true if all the objects are equal (using {eql?}) operator
      def instance_variables_equal(**kw_args)
        kw_args.all? do |var_name, value|
          value.eql?(instance_variable_get(var_name))
        end
      end
    end
  end
end
