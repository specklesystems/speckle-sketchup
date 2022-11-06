# frozen_string_literal: true

module SpeckleSystems
  module SpeckleConnector
    # from thomthom
    # https://github.com/thomthom/true-bend/blob/master/src/tt_truebend/debug.rb

    # @note Debug method to reload the plugin.
    #
    # @example
    #   SpeckleSystems::SpeckleConnector.reload
    #
    # @return [Integer] Number of files reloaded.
    def self.reload
      load(__FILE__)
      pattern = File.join(__dir__, '**/*.rb')
      Dir.glob(pattern).each { |file| load(file) }
         .size
    end
  end
end
