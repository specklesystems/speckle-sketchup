# frozen_string_literal: true

module SpeckleConnector
  # Worker class that keeps a list of jobs and can do the jobs
  class Worker
    # @return [Array<String>]
    attr_reader :jobs

    def initialize(jobs)
      @jobs = jobs
    end

    def add_job(job)
      @jobs.append(job)
    end

    def add_jobs(new_jobs)
      @jobs += new_jobs
    end

    def work
      job = @jobs.pop
      puts "Working on #{job}"
      # sleep 0.01
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
      unless jobs?
        # update(dialog, 'Work finished!')
        action.call
        return
      end

      work while (Time.now.to_f - last_update_time < 0.05) && jobs?

      puts 'Stop working to update status'
      action.call
      # update(dialog, "working on #{next_job}")
      last_update_time = Time.now.to_f
      UI.start_timer(0, false) do
        puts 'Resuming work from a timer'
        do_work(last_update_time, &action)
      end
    end
  end
end
