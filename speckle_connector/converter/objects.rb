require "sketchup"

module SpeckleSystems::SpeckleConnector::Objects
  class Point
    attr_accessor :units, :x, :y, :z
    
    def initialize(x = 0.0, y = 0.0, z = 0.0, units = "m")
      @x, @y, @z, @units = x, y, z, units
    end
  end

  class Line
    def initialize

    end
  end
end
