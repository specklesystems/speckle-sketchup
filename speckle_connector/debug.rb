# frozen_string_literal: true

# Speckle connector module to enable multiplayer mode ON!
module SpeckleConnector
  # from thomthom
  # https://github.com/thomthom/true-bend/blob/master/src/tt_truebend/debug.rb

  # @note Debug method to reload the plugin.
  #
  # @example
  #   SpeckleConnector.reload
  #
  # @return [Integer] Number of files reloaded.
  # rubocop:disable SketchupSuggestions/FileEncoding
  def self.reload
    load(__FILE__)
    pattern = File.join(__dir__, '**/*.rb')
    Dir.glob(pattern).each { |file| load(file) }
       .size
  end
  # rubocop:enable SketchupSuggestions/FileEncoding
end
