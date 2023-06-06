# frozen_string_literal: true

module SpeckleConnector
  # Helper module for logging.
  module Log
    def self.write_to_file(text, file_name = 'log', path = "#{ENV['HOME']}/Desktop")
      file_path = path + "/#{file_name}.json"
      File.delete(file_path) if File.exist?(file_path)
      File.write(file_path, text)
    end
  end
end
