# frozen_string_literal: true


module SpeckleConnector3
  module Settings
    # Base card setting for sketchup connector.
    class CardSetting < Hash
      # @return [String, NilClass] id of the setting
      attr_reader :id

      # @return [String, NilClass] title of the setting
      attr_reader :title

      # @return [String, NilClass] type of the setting, "string", "boolean"...
      attr_reader :type

      # @return [String, Integer, Float, TrueClass, FalseClass] value of the setting
      attr_reader :value

      # @return [Array<String>] list of values for dropdown
      attr_reader :enum

      def initialize(id:, title:, type:, value:, enum: nil)
        super()
        @id = id
        @title = title
        @type = type
        @value = value
        @enum = enum
        self[:id] = id if id
        self[:title] = title if title
        self[:type] = type if type
        self[:value] = value if value
        self[:enum] = enum if enum
      end

      def self.get_setting_from_ui_data(data)
        data.values.collect do |d|
          CardSetting.new(id: d['id'], title: d['title'], type: d['type'],
                          value: d['value'], enum: d['enum'] ? d['enum'].values : nil) # UI give array as object damn!
        end
      end

      def self.get_filter_from_document(data)
        data.values.collect do |d|
          CardSetting.new(id: d['id'], title: d['title'], type: d['type'],
                          value: d['value'], enum: d['enum'] ? d['enum'].values : nil) # UI give array as object damn!
        end
      end
    end
  end
end
