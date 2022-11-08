# frozen_string_literal: true

require 'pathname'

module SpeckleConnector
  dir = __dir__.dup
  dir.force_encoding('UTF-8') if dir.respond_to?(:force_encoding)
  SPECKLE_SRC_PATH = Pathname.new(File.expand_path('..', dir)).cleanpath.to_s
end
