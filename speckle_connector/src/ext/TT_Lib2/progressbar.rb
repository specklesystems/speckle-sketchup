#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'sketchup.rb'

module SpeckleConnector
  # Wrapper for displaying progress to the user.
  #
  # @since 2.5.0
  class TT::Progressbar

    # Creates a Progressbar that keeps track of time and displays progress back to
    # the user.
    #
    # Whenever the UI is updated with status info +TT::SketchUp.refresh+ is called
    # in order to try and refresh the SketchUp UI.
    #
    # Use +value=+ to set a spesific value, or +next+ to increment the value.
    #
    # If +range+ is +nil+ then it only keeps track of time.
    #
    #  progress = TT::Progressbar.new( entities, 'Doing something' )
    #  entities.each { |e|
    #   doSomething(e)
    #   progress.next
    #  }
    #  Sketchup.status_text = "Something took #{progress.estimated_time_left(true)} to complete."
    #
    # @param [Mixed] range Object that gives the amount of work to be done.
    # @param [String] task_name String that will be displayed in the statusbar.
    # @param [Integer] decimals_places Number of decimals for the percentage in the statusbar.
    #
    # @since 2.5.0
    def initialize( range=nil, task_name='Processing', decimals_places=1 )
      if range.nil?
        @start = 0
        @end = 0
      elsif range.is_a?( Range )
        @start = range.first
        @end = range.last
      elsif range.is_a?( Numeric )
        @start = 0
        @end = range
      else
        [:length, :count, :size, :count_instances].each { |method|
          if range.respond_to?( method )
            @start = 0
            @end = range.send( method )
          end
        }
        if @start.nil?
          raise( ArgumentError, 'Must be Range, Numeric or collection.' )
        end
      end
      @start = @start.to_f
      @end = @end.to_f
      @task_name = task_name
      @decimals = decimals_places.to_i
      reset
    end


    # Advance the current value one step and updates the UI.
    #
    # @param [Numeric] amount
    #
    # @return [Numeric]
    # @since 2.5.0
    def increment(amount=1)
      @value += amount.abs
      updateUI
      @value
    end
    alias :next :increment


    # Set the current value updates the UI.
    #
    # @param [Numeric] new_value
    #
    # @return [Numeric]
    # @since 2.5.0
    def value=(new_value)
      @value = new_value
      updateUI
      @value
    end


    # Returns the size of the process range.
    #
    # @return [Numeric]
    # @since 2.5.0
    def size
      @end - @start
    end


    # Returns the current value.
    #
    # @return [Numeric]
    # @since 2.5.0
    def index
      @value - @start
    end


    # Returns the total running time.
    #
    # @param [Boolean] format
    #
    # @return [Numeric|String]
    # @since 2.5.0
    def elapsed_time(format=false)
      elapsed = Time.now - @start_time
      (format) ? TT::format_time(elapsed) : elapsed
    end


    # Returns the estimated remaining time.
    #
    # @param [Boolean] format
    #
    # @return [Numeric|String]
    # @since 2.5.0
    def estimated_time_left(format=false)
      elapsed = elapsed_time
      ratio = size / index
      remaining = (elapsed * ratio) - elapsed
      (format) ? TT::format_time(remaining) : remaining
    end


    private


    # Resets the progressbar to initial state.
    #
    # @return [Nil]
    # @since 2.5.0
    def reset
      @start_time = Time.now
      @last_update = @start_time.dup
      @value = @start
      updateUI if size > 0
      nil
    end


    # Updates the UI with the current progress.
    #
    # @return [Boolean] +true+ if the UI was given an update, +false+ otherwise.
    # @since 2.5.0
    def updateUI
      return false if @value > @end
      return false if Time.now - @last_update < 0.1 # Cap update rate (in seconds).
      progress = 100 * ( index / size )
      e = "Elapsed time: #{elapsed_time(true)}"
      left = estimated_time_left
      r = "Remaining: #{TT::format_time(left)}"
      at = ( Time.now + left ).strftime('%H:%M') # Estimated time of completion
      string = "#{@task_name} %.#{@decimals}f%% - #{e} - #{r} (#{at})"
      Sketchup.status_text = sprintf(string, progress)
      TT::SketchUp.refresh
      @last_update = Time.now
      true
    end

  end # class TT::Progressbar
end
