# frozen_string_literal: true

require 'pathname'
require_relative 'platform_constants'

# Speckle connector module to enable multiplayer mode ON!
module SpeckleConnector
  dir = __dir__.dup
  dir.force_encoding('UTF-8') if dir.respond_to?(:force_encoding)
  SPECKLE_SRC_PATH = Pathname.new(File.expand_path('..', dir)).cleanpath.to_s
  SPECKLE_APPDATA_PATH = case OPERATING_SYSTEM
                         when OS_WIN
                           path = ENV.fetch('APPDATA')
                           Pathname.new(File.join(path, 'Speckle')).cleanpath.to_s
                         when OS_MAC
                           File.join(Dir.home, 'Library/Application Support/Speckle')
                         else
                           raise 'Speckle could not determine your Appdata path'
                         end
end
