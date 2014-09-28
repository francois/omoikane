require "omoikane/job"
require "omoikane/errors"

module Omoikane
  # A Facade to the jobs directory.
  #
  # Implements a simple and efficient API for the app server to use.
  class JobsController
    def initialize(jobsdir, mapper)
      @jobsdir = jobsdir
      @mapper  = mapper
    end

    # Indicates where in the filesystem to find existing jobs
    attr_reader :jobsdir, :mapper

    # @return Array<Job> Returns the list of job objects
    def jobs
      jobdirs = Dir[File.join(jobsdir, "*")]
      jobs = jobdirs.map{|jobdir| File.basename(jobdir)}.map(&method(:find_job))

      ctimes = jobdirs.map do |jobdir|
        File.ctime(jobdir)
      end

      ctimes.zip(jobs).sort_by{|ctime, job| ctime}.reverse.map(&:last)
    end

    # @return Job Returns a minimally hydrated Job object, enough to know the job's status.
    def job_status(jobid)
      find_job(jobid)
    end

    # @return Array<Array<String>> Returns the n'th page of results for this job, or raises JobNotFinished.
    def job_results(jobid, page, page_size)
      job = find_job(jobid)
      job.results(page, page_size)
    end

    private

    def find_job(jobid)
      attributes = mapper.hash_for_job(File.join(jobsdir, jobid))
      Omoikane::Job.new(attributes)
    end
  end
end
