# frozen_string_literal: true

require_relative '../base'
require_relative '../other/transform'
require_relative '../other/block_definition'
require_relative '../other/block_instance'
require_relative '../../constants/type_constants'
require_relative '../../sketchup_model/dictionary/dictionary_handler'

module SpeckleConnector3
  module SpeckleObjects
    module GIS
      def self.get_definition_name(obj, attributes)
        return obj['name'] unless obj['name'].nil?

        return attributes['name'] unless attributes['name'].nil?

        return "def::#{obj['id']}"
      end

      def self.get_qgis_attributes(obj)
        attributes = obj['attributes'].to_h
        speckle_properties = %w[id speckle_type units applicationId]
        speckle_properties.each { |key| attributes.delete(key) }
        attributes
      end
    end
  end
end
