# frozen_string_literal: true

require 'json'
require_relative '../immutable/immutable'
require_relative 'base'

module SpeckleConnector
  module SpeckleObjects
    # Object reference to send it to Speckle server. It contains closure table to store children objects.
    class ObjectReference < Base

      attr_reader :closure, :referenced_id, :application_id

      def initialize(referenced_id, application_id, closure)
        @speckle_type = 'reference'
        @closure = closure
        @referenced_id = referenced_id
        @application_id = application_id
        super()
        update(
          {
            speckle_type: 'reference',
            referencedId: referenced_id,
            __closure: closure
          }
        )
      end
    end
  end
end
