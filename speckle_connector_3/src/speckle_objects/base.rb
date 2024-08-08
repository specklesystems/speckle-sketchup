# frozen_string_literal: true

require 'json'
require_relative '../immutable/immutable'

module SpeckleConnector3
  module SpeckleObjects
    # Dynamic Base object to send it to Speckle server.
    class Base < Hash
      include Immutable::ImmutableUtils

      attr_reader :speckle_type, :application_id, :id

      def initialize(speckle_type: 'Base', application_id: nil, id: '')
        @speckle_type = speckle_type
        @application_id = application_id
        @id = id
        super()
        update(
          {
            speckle_type: speckle_type,
            applicationId: application_id,
            id: id
          }
        )
      end

      def self.with_detached_layers(detached_layers)
        Base.new.merge(detached_layers)
      end

      def []=(key, val)
        # Clear if setting string or symbol
        if ((key.is_a? String) || (key.is_a? Symbol)) && include?(key)
          delete key.to_sym
          delete key.to_s
        end
        # TODO: Control here if we have conditions to add dynamic property to
        merge!({ key => val })
      end
    end
  end
end
