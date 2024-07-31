# frozen_string_literal: true

# Speckle connector module to enable multiplayer mode ON!
module SpeckleConnector3
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
    # TODO: Here is a opportunity to improve reloading process.
    #  We can cache last edited time of the each file later to check which file need to be reloaded.
    Dir.glob(pattern).each { |file| load(file) unless file.include?('bootstrap') }
       .size
  end
  # rubocop:enable SketchupSuggestions/FileEncoding
end
