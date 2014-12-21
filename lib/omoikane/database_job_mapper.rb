require "oj"
require "csv"
require "escape"
require "active_support/core_ext/hash/keys" # Hash#symbolize_keys

module Omoikane
  # Implements a Data Mapper for database and disk-based jobs to in-memory Job objects
  class DatabaseJobMapper
    def hash_for_job(jobdir, page, rows_per_page)
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

      columns = []
      columns = headers(jobdir, "results.csv.gz") if exists?(jobdir, "results.csv.gz")

      results = []
      results = body(jobdir, "results.csv.gz", page, rows_per_page) if exists?(jobdir, "results.csv.gz")

      details = Oj.load(details_txt) if details_txt
      (details || {}).symbolize_keys.merge(
        id: File.basename(jobdir),
        state_changes: state_changes,
        current_state: current_status,
        query: query,
        job_log: job_log,
        explain_stdout: explain_stdout,
        explain_stderr: explain_stderr,
        rows_count: rows_count,
        run_stderr: run_stderr,
        columns: columns,
        results: results
      )
    end

    def write_job(jobdir, hash)
      # Clean out any weed or chaff: start with a clean slate
      Dir[path(jobdir, "*")].each{|fname| File.unlink(fname)}

      details = {
        author: hash.fetch(:author),
        title: hash.fetch(:title).respond_to?(:empty?) && hash.fetch(:title).empty? ? nil : hash.fetch(:title),
      }

      File.open(path(jobdir, "details.json"), "w") {|io| io.puts Oj.dump(details)}

      File.open(path(jobdir, "state-changes.csv"), "w") do |io|
        CSV(io, col_sep: ",", row_sep: "\n") do |csv|
          csv << [Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%N%z"), "queued"]
        end
      end

      # Must be last, because this file triggers the worker
      File.open(path(jobdir, "query.sql"), "w") {|io| io.puts hash.fetch(:query)}
    end

    def job_results_path(jobdir)
      path(jobdir, "results.csv.gz")
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
