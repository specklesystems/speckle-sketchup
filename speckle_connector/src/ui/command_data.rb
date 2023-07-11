# frozen_string_literal: true

require 'json'

module SpeckleConnector
  module Ui
    # Command structure to handle it with dialog.exec_callback
    CommandData = Struct.new(:name, :data)

    # Parser class for commands that comes from dialog to ruby engine.
    class CommandParser
      # @return [Array<Ui::Command>] parsed commands.
      def self.parse_commands(data)
        data = JSON.parse(data) if data.is_a? String
        return [parse(data)].compact unless data.is_a?(Array)

        data.collect { |command| parse(command) }.compact
      end

      def self.parse(command)
        return nil unless command.is_a?(Hash)

        name = command['name']

        return nil unless name.is_a?(String)

        arguments = command['data'].nil? ? nil : command['data']['arguments']
        request_id = command['data'].nil? ? nil : command['data']['request_id']

        unless arguments.nil?
          arguments = {}
          arguments[:request_id] = request_id
        end

        CommandData.new(name.to_sym, arguments)
      end
    end
  end
end
