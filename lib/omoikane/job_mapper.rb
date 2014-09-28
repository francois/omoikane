require "csv"
require "oj"
require "active_support/core_ext/hash/keys" # Hash#symbolize_keys

module Omoikane
  # Implements a Data Mapper for disk-based jobs to in-memory Job objects
  class JobMapper
    def hash_for_job(jobdir)
      state_changes  = read_state_changes(jobdir)
      current_status = state_changes.last.last
      query          = read(jobdir, "query.sql")

      job_log        = read(jobdir, "job.log")                  if exists?(jobdir, "job.log")
      explain_query  = read(jobdir, "explain-query.sql")        if exists?(jobdir, "explain-query.sql")
      explain_stdout = read(jobdir, "explain-query-stdout.txt") if exists?(jobdir, "explain-query-stdout.txt")
      explain_stderr = read(jobdir, "explain-query-stderr.txt") if exists?(jobdir, "explain-query-stderr.txt")
      rows_count     = read(jobdir, "rows-count.csv").to_i      if exists?(jobdir, "rows-count.csv")
      run_query      = read(jobdir, "run-query.sql")            if exists?(jobdir, "run-query.sql")
      run_stderr     = read(jobdir, "run-query-stderr.txt")     if exists?(jobdir, "run-query-stderr.txt")
      details_txt    = read(jobdir, "details.json")             if exists?(jobdir, "details.json")

      details = Oj.load(details_txt) if details_txt
      (details || {}).symbolize_keys.merge(
        id: File.basename(jobdir),
        state_changes: state_changes,
        current_status: current_status,
        query: query,
        job_log: job_log,
        explain_stdout: explain_stdout,
        explain_stderr: explain_stderr,
        rows_count: rows_count,
        run_stderr: run_stderr
      )
    end

    private

    def path(jobdir, filename)
      File.join(jobdir, filename)
    end

    def read(jobdir, filename)
      File.read(path(jobdir, filename))
    end

    def exists?(jobdir, filename)
      File.exist?(path(jobdir, filename))
    end

    def read_state_changes(jobdir)
      Array.new.tap do |states|
        CSV.foreach(path(jobdir, "state-changes.csv"), col_sep: ",", row_sep: "\n") do |row|
          # row[0] -> timestamp with nanosecond precision
          # row[1] -> the state we entered at that timestamp
          states << [row[0], row[1]]
        end
      end.sort
    end
  end
end
