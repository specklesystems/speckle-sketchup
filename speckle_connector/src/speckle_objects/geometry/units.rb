# frozen_string_literal: true

module SpeckleConnector
  module SpeckleObjects
    module Geometry
      module Units
        MILLIMETERS = 'mm'
        CENTIMETERS = 'cm'
        METERS = 'm'
        KILOMETERS = 'km'
        INCHES = 'in'
        FEET = 'ft'
        YARDS = 'yd'
        MILES = 'mi'
        NONE = 'none'

        # USInches = "us_in" the smelliest ones, can add later if people scream "USA #1"
        USFEET = 'us_ft' # it happened, absolutely gross

        SUPPORTED_UNITS = [MILLIMETERS, CENTIMETERS, METERS, KILOMETERS,
                           INCHES, FEET, USFEET, YARDS, MILES, NONE].freeze

        CONVERSION_TABLE = {
          MILLIMETERS => {
            CENTIMETERS => 0.1,
            METERS => 0.001,
            KILOMETERS => 1e-6,
            INCHES => 0.0393701,
            FEET => 0.00328084,
            USFEET => 0.0032808333,
            YARDS => 0.00109361,
            MILES => 6.21371e-7
          },
          CENTIMETERS => {
            MILLIMETERS => 10,
            METERS => 0.01,
            KILOMETERS => 1e-5,
            INCHES => 0.393701,
            FEET => 0.0328084,
            USFEET => 0.0328083333,
            YARDS => 0.0109361,
            MILES => 6.21371e-6
          },
          METERS => {
            MILLIMETERS => 1000,
            CENTIMETERS => 100,
            KILOMETERS => 0.001,
            INCHES => 39.3701,
            FEET => 3.28084,
            USFEET => 3.28083333,
            YARDS => 1.09361,
            MILES => 0.000621371
          },
          KILOMETERS => {
            MILLIMETERS => 1e6,
            CENTIMETERS => 100000,
            METERS => 1000,
            INCHES => 39370.1,
            FEET => 3280.84,
            USFEET => 3280.83333,
            YARDS => 1093.61,
            MILES => 0.621371
          },
          INCHES => {
            MILLIMETERS => 25.4,
            CENTIMETERS => 2.54,
            METERS => 0.0254,
            KILOMETERS => 2.54e-5,
            FEET => 0.0833333,
            USFEET => 0.0833331667,
            YARDS => 0.027777694,
            MILES => 1.57828e-5
          },
          FEET => {
            MILLIMETERS => 304.8,
            CENTIMETERS => 30.48,
            METERS => 0.3048,
            KILOMETERS => 0.0003048,
            INCHES => 12,
            USFEET => 0.999998,
            YARDS => 0.333332328,
            MILES => 0.000189394
          },
          USFEET => {
            MILLIMETERS => 120000.0 / 3937.0,
            CENTIMETERS => 12000.0 / 3937.0,
            METERS => 1200.0 / 3937.0,
            KILOMETERS => 1.2 / 3937.0,
            INCHES => 12.000024,
            FEET => 1.000002,
            YARDS => 1.000002 / 3.0,
            MILES => 1.000002 / 5280.0
          },
          YARDS => {
            MILLIMETERS => 914.4,
            CENTIMETERS => 91.44,
            METERS => 0.9144,
            KILOMETERS => 0.0009144,
            INCHES => 36,
            FEET => 3,
            USFEET => 2.999994,
            MILES => 1.0 / 1760.0
          },
          MILES => {
            MILLIMETERS => 1.609e6,
            CENTIMETERS => 160934,
            METERS => 1609.34,
            KILOMETERS => 1.60934,
            INCHES => 63360,
            FEET => 5280,
            USFEET => 5279.98944002112,
            YARDS => 1759.99469184
          },
          NONE => { NONE => 1 }
        }.freeze

        def self.unit_supported?(unit)
          SUPPORTED_UNITS.include?(unit)
        end

        # USYards = "us_yd" the smelliest ones, can add later if people scream "USA #1"
        # USMiles = "us_mi" the smelliest ones, can add later if people scream "USA #1"

        def self.get_conversion_factor(from, to)
          from = get_units_from_string(from)
          to = get_units_from_string(to)
          CONVERSION_TABLE[from][to] || 1
        end

        def self.get_units_from_string(unit)
          return nil if unit.nil?

          case unit.downcase
          when 'mm', 'mil', 'millimeter', 'millimeters', 'millimetres'
            MILLIMETERS
          when 'cm', 'centimetre', 'centimeter', 'centimetres', 'centimeters'
            CENTIMETERS
          when 'm', 'meter', 'metre', 'meters', 'metres'
            METERS
          when 'inches', 'inch', 'in'
            INCHES
          when 'feet', 'foot', 'ft'
            FEET
          when 'ussurveyfeet'
            USFEET
          when 'yard', 'yards', 'yd'
            YARDS
          when 'miles', 'mile', 'mi'
            MILES
          when 'kilometers', 'kilometer', 'km'
            KILOMETERS
          when 'none'
            NONE
          else
            raise "Cannot understand what unit #{unit} is."
          end
        end

        def self.get_encoding_from_unit(unit)
          case unit
          when MILLIMETERS
            1
          when CENTIMETERS
            2
          when METERS
            3
          when KILOMETERS
            4
          when INCHES
            5
          when FEET
            6
          when YARDS
            7
          when MILES
            8
          else
            0
          end
        end

        def self.get_unit_from_encoding(unit)
          case unit
          when 1
            MILLIMETERS
          when 2
            CENTIMETERS
          when 3
            METERS
          when 4
            KILOMETERS
          when 5
            INCHES
          when 6
            FEET
          when 7
            YARDS
          when 8
            MILES
          else
            NONE
          end
        end
      end
    end
  end
end
