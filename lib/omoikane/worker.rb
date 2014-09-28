require "omoikane/logging"
require "set"

module Omoikane
  # The main background worker: schedules jobs to be run when required.
  #
  # The worker is mostly stateless: it remembers jobs it has already seen and
  # processed, but does not remember anything beyond that.
  class Worker
    def initialize(jobsdir, jobrunner_path)
      @jobsdir = jobsdir
      @jobrunner_path = jobrunner_path
      @cycle_count = 0

      @running = true
      @terminated = Set.new

      # The list of jobs we already know about
      # In order to not launch any existing queries, mark every existing job as known on start
      @known = Dir[File.join(JOBSDIR, "*", "query.sql")].
        map{|query_file| File.dirname(query_file)}.
        to_set

      trap("TERM", &method(:stop_running))
      trap("CHLD", &method(:record_terminated_child))
    end

    # The path to the directory containing jobs
    attr_reader :jobsdir

    # Whether we're running or not
    attr_reader :running

    # The set of PIDs that terminated in the last cycle
    attr_reader :terminated

    # The number of times we've run our event loop
    attr_reader :cycle_count

    # The set of jobs we know about
    # This set can grow to very large proportions if the process runs for
    # very long periods of time.
    attr_reader :known

    # The path to the omoikane-job executable
    attr_reader :jobrunner_path

    # The main event loop
    def run
      logger.info "Omoikane worker running!"
      while running do
        sleep 1

        log_terminated_jobs
        maybe_log_we_are_still_running
        newjobs = find_new_jobs
        logger.debug "Found #{newjobs.size} new jobs to launch"
        launch(newjobs)
      end

      logger.info "#{File.basename($0)} terminated"
    end

    private

    def log_terminated_jobs
      terminated.each do |pid|
        logger.info "Process #{pid} terminated"
      end

      terminated.clear
    end

    def maybe_log_we_are_still_running
      increment_cycle_count
      logger.info "Still going..." if (cycle_count % 300).zero?
    end

    def find_new_jobs
      Dir[File.join(JOBSDIR, "*", "query.sql")].
        map{|query_file| File.dirname(query_file)}.
        reject{|jobdir| known.include?(jobdir)}
    end

    def launch(newjobs)
      newjobs.each do |jobdir|
        self.known << jobdir
        pid = fork { exec(jobrunner_path, jobdir) }
        logger.info "Launched #{jobdir.inspect} as #{pid}"
      end
    end

    def increment_cycle_count
      @cycle_count += 1
    end

    def record_terminated_child(_)
      self.terminated << Process.wait
    end

    def stop_running(_)
      @running = false
    end
  end
end
