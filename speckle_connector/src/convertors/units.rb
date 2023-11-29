# frozen_string_literal: true

module SpeckleConnector
  module Converters
    SKETCHUP_UNITS = { 0 => 'in', 1 => 'ft', 2 => 'mm', 3 => 'cm', 4 => 'm', 5 => 'yd' }.freeze
    SKETCHUP_UNIT_STRINGS = { 'm' => 'm', 'mm' => 'mm', 'ft' => 'feet', 'in' => 'inch', 'yd' => 'yard',
                              'cm' => 'cm' }.freeze
  end
end
