require "omoikane/job"
require "omoikane/errors"

module Omoikane
  # A Facade to the jobs directory.
  #
  # Implements a simple and efficient API for the app server to use.
  class FileJobsController
    def initialize(jobsdir, mapper)
      @jobsdir = jobsdir
      @mapper  = mapper
    end

    # Indicates where in the filesystem to find existing jobs
    attr_reader :jobsdir, :mapper

    def submit_job(id, job)
      jobdir = File.join(jobsdir, id)
      Dir.mkdir(jobdir) unless File.directory?(jobdir)

      mapper.write_job(jobdir, {
        author: job.author,
        title: job.title,
        query: job.query
      })
    end

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
    def job_status(jobid, page=1, rows_per_page=25)
      find_job(jobid, page, rows_per_page)
    end

    def job_results_path(jobid)
      jobdir = File.join(jobsdir, jobid)
      mapper.job_results_path(jobdir)
    end

    private

    def find_job(jobid, page=1, rows_per_page=25)
      raise ArgumentError, "page must be >= 1, received #{page.inspect}" unless page >= 1
      raise ArgumentError, "rows_per_page must be > 1, received #{rows_per_page.inspect}" unless rows_per_page > 1

      attributes = mapper.hash_for_job(File.join(jobsdir, jobid), page, rows_per_page)
      Omoikane::Job.new(attributes)
    end
  end
end
