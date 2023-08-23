#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'model.rb'
require_relative 'progressbar.rb'

module SpeckleConnector
  # Wrapper class for enumerating a collection with UI feedback and optional
  # operation wrapping.
  #
  #  task = TT::SimpleTask.new( 'HelloWorld', model.entities, true )
  #  task.run { |entity|
  #    someWork( entity )
  #  }
  #
  # @since 2.5.0
  class TT::SimpleTask

    # Iterates the given +collection+, yielding each item while displaying progress
    # back to the user.
    #
    # When +model+ is +nil+ the task is not wrapped in an operation.
    #
    # When +model+ is +Sketchup::Model+ the task is wrapped in an operation which
    # aborts upon errors.
    #
    # @param [String] task_name
    # @param [Enumerable] collection
    # @param [Nil||Sketchup::Model] model
    # @param [Integer] decimals_places
    #
    # @since 2.5.0
    def initialize( task_name, collection, model=nil, decimals_places=1 )
      unless collection.is_a?( Enumerable )
        raise ArgumentError, 'collection argument must be Enumerable'
      end
      if model && !model.is_a?( Sketchup::Model )
        raise ArgumentError, 'model argument must be Sketchup::Model or nil'
      end
      @task_name = task_name
      @collection = collection
      @model = model
      @decimals_places = decimals_places
    end

    # @return [Nil]
    # @since 2.5.0
    def run
      if @model
        TT::Model.start_operation( @task_name, @model ) # rubocop:disable SketchupPerformance/OperationDisableUI
      end

      progress = TT::Progressbar.new( @collection, @task_name, @decimals_places )
      for item in @collection
        yield( item )
        progress.next
      end

      if @model
        @model.commit_operation
      end
      Sketchup.status_text = "#{@task_name} complete! (#{progress.elapsed_time(true)})"
      nil
    rescue => e
      if @model
        @model.abort_operation
      end
      #raise e
      puts e.message
      puts e.backtrace.join("\n")
      #UI.messagebox("#{e.message}\n\n#{e.backtrace.join("\n")}", MB_MULTILINE)
    end

  end # class TT::SimpleTask
end
