# frozen_string_literal: true

require 'json'
require_relative '../immutable/immutable'

module SpeckleConnector
  module SpeckleObjects
    class Base < Hash
      include Immutable::ImmutableUtils

      attr_reader :speckle_type

      attr_reader :applicationId

      attr_reader :totalChildrenCount

      attr_reader :id

      def initialize(speckle_type: 'Base', total_children_count: 0, application_id: nil, id: nil)
        @speckle_type = speckle_type
        @totalChildrenCount = total_children_count
        @applicationId = application_id
        @id = id
        super()
        update(
          {
            speckle_type: speckle_type,
            totalChildrenCount: total_children_count,
            applicationId: application_id,
            id: id
          }
        )
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
