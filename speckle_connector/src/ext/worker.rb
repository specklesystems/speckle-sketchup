# frozen_string_literal: true

module SpeckleConnector

  NOT_STARTED = 0
  PENDING = 1
  SKIPPED = 2
  DONE = 3
  FAILED = 4

  class Job


    attr_accessor :note
    attr_accessor :status
    attr_reader :id
    attr_reader :action

    def initialize(id, &action)
      @id = id
      @action = action
      @status = NOT_STARTED
    end

    def run
      action.call(id)
      @status = DONE
    end
  end

  # Worker class that keeps a list of jobs and can do the jobs
  class Worker
    # @return [Array<Job>]
    attr_reader :jobs

    def initialize(jobs = [])
      @jobs = jobs
    end

    # @param job [Job]
    def add_job(job)
      @jobs.append(job)
    end

    # @param new_jobs [Array<Job>]
    def add_jobs(new_jobs)
      new_jobs.each { |job| add_job(job) }
    end

    def work
      not_started_jobs = @jobs.select {|job| job.status == NOT_STARTED }
      job = not_started_jobs.last
      job.status = PENDING
      job = @jobs.select {|job| job.status == PENDING }.last
      job.run
      # puts "Working on #{job}"
      # sleep 0.01
    end

    def pending_jobs?
      @jobs.select {|job| job.status == PENDING }.any?
    end

    def not_started_jobs?
      @jobs.select {|job| job.status == NOT_STARTED }.any?
    end

    def jobs?
      @jobs.any?
    end

    def next_job
      @jobs.last
    end

    # Recursive function that updates the status and makes a recursive call
    # inside the timer, so the UI is actually updated
    def do_work(last_update_time, &action)
      unless not_started_jobs?
        # end job call if any?
        # action.call
        return
      end

      work while (Time.now.to_f - last_update_time < 0.2) && not_started_jobs?

      #puts 'Stop working to update status'
      action.call
      last_update_time = Time.now.to_f
      UI.start_timer(0, false) do
        # puts 'Resuming work from a timer'
        do_work(last_update_time, &action)
      end
    end
  end
end
