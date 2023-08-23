#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Special Proc like object that limits the frequency it's executed. Designed to
# be used with +change+ events for TT::GUI::Textbox.
#
# @since 2.7.0

module SpeckleConnector
  class TT::DeferredEvent

    attr_accessor( :suppress_event_if_value_not_changed )

    # @param [Float] delay Maximum frequency the event can be executed.
    # @param [Proc] block
    #
    # @since 2.7.0
    def initialize( delay = 0.2, &block )
      @proc = block
      @delay = delay
      @last_value = nil
      @timer = nil
      @suppress_event_if_value_not_changed = true
    end

    # @param [Mixed] value Must be different from last call in order to trigger.
    #
    # @return [Boolean] True is the event was executed.
    # @since 2.7.0
    def call( value )
      return false if @suppress_event_if_value_not_changed && value == @last_value
      UI.stop_timer( @timer ) if @timer
      @timer = UI.start_timer( @delay, false ) {
        UI.stop_timer( @timer ) # Ensure it only runs once.
        @proc.call( value )
      }
      true
    end

  end # class DeferredEvent
end
