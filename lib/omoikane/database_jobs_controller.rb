require "omoikane/job"
require "omoikane/errors"
require "fileutils"

module Omoikane
  class DatabaseJobsController
    def initialize(db, jobsdir, mapper)
      @db      = db
      @jobsdir = jobsdir
      @mapper  = mapper
    end

    attr_reader :db, :jobsdir, :mapper

    def submit_job(id, job)
      jobdir = File.join(jobsdir, id)
      FileUtils.mkdir_p(jobdir)
      Dir[path(jobdir, "*")].each{|fname| File.unlink(fname)}

      db.transaction do
        db[:queries].insert(
          id: id,
          submitted_at: Time.now.utc,
          author: job.author,
          title: job.title)

        db[:query_states].insert(
          id: id,
          updated_at: Time.now.utc,
          state: "queued")

        File.open(File.join(jobdir, "explain.sql"), "w") do |io|
          io.puts "EXPLAIN"
          io.puts job.query
        end

        File.open(File.join(jobdir, "query.sql"), "w") do |io|
          io.puts job.query
        end

        # Creating this row triggers job execution
        # (using the database as a job queue)
        db[:pending].insert(id: id)
      end
    rescue Exception
      FileUtils.rm_rf(File.join(jobsdir, id))
      raise
    end

    # details.json  explain-query.sql  explain-query-stderr.txt  explain-query-stdout.txt  job.log  query.sql  results.csv.gz  rows-count.csv  run-query.sql  run-query-stderr.txt  state-changes.csv
    def jobs
      queries = db[:queries].order(:submitted_at).all.reverse
      states  = db[:query_states].
        filter(id: queries.map{|row| row.fetch(:id)}).
        order(:id, :updated_at).
        all

      queries.map do |row|
        jobdir = File.join(jobsdir, row.fetch(:id))
        state_changes = states.
          select{|state| state.fetch(:id) == row.fetch(:id)}.
          map{|state| [state.fetch(:updated_at), state.fetch(:state)]}

        Omoikane::Job.new(
          id: row.fetch(:id),
          state_changes: state_changes,
          current_state: state_changes.last.last,
          author: row.fetch(:author),
          title: row.fetch(:title),
          query: read(File.join(jobsdir, row.fetch(:id), "query.sql")),
          rows_count: row.fetch(:rows_count),
          explain_stdout: read(File.join(jobdir, "explain-query-stdout.txt")),
          explain_stderr: read(File.join(jobdir, "explain-query-stderr.txt")),
          run_stderr: read(File.join(jobdir, "run-query-stderr.txt")),
          columns: [],
          results: [])
      end
    end

    def job_status(jobid, page=1, rows_per_page=25)
      jobdir = File.join(jobsdir, jobid)
      row = db[:queries].filter(id: jobid).first
      state_changes = db[:query_states].
        select(:updated_at, :state).
        filter(id: jobid).
        order(:updated_at).
        map{|state| [state.fetch(:updated_at), state.fetch(:state)]}

      Omoikane::Job.new(
        id: row.fetch(:id),
        state_changes: state_changes,
        current_state: state_changes.last.last,
        author: row.fetch(:author),
        title: row.fetch(:title),
        query: read(File.join(jobsdir, row.fetch(:id), "query.sql")),
        rows_count: row.fetch(:rows_count).to_i - 1,
        explain_stdout: read(File.join(jobdir, "explain-query-stdout.txt")),
        explain_stderr: read(File.join(jobdir, "explain-query-stderr.txt")),
        run_stderr: read(File.join(jobdir, "run-query-stderr.txt")),
        columns: headers(jobdir, "results.csv.gz"),
        results: body(jobdir, "results.csv.gz", page, rows_per_page))
    end

    def job_results_path(jobid)
      jobdir = File.join(jobsdir, row.fetch(:id))
      path(jobdir, "results.csv.gz")
    end

    private

    def path(jobdir, filename)
      File.join(jobdir, filename)
    end

    # Behaves much like File::read, but returns nil if the file does not exist.
    def read(path)
      File.file?(path) ? File.read(path) : nil
    end

    def headers(jobdir, filename)
      gunzip = Escape.shell_command(["gunzip", "--stdout", path(jobdir, filename)])
      head = Escape.shell_command(["head", "--lines", "1", "--quiet"])
      cmd = "#{gunzip} | #{head}"

      IO.popen(cmd) do |io|
        CSV.new(io, headers: false).readlines.first
      end
    end

    def body(jobdir, filename, page, rows_per_page)
      gunzip      = Escape.shell_command(["gunzip", "--stdout", path(jobdir, filename)])
      skip_header = Escape.shell_command(["tail", "--lines", "+2"])
      topn_pages  = Escape.shell_command(["head", "--lines", "#{page * rows_per_page}"])
      last_page   = Escape.shell_command(["tail", "--lines", "#{rows_per_page}"])
      cmd = "#{gunzip} | #{skip_header} | #{topn_pages} | #{last_page}"

      IO.popen(cmd) do |io|
        CSV.new(io, headers: false).readlines
      end
    end
  end
end
