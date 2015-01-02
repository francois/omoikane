require "sequel"
require "models/project"
require "models/query"
require "models/run"

class RunQuery < Sequel::Model
  many_to_one :run,                            key: :run_id
  many_to_one :project,                        key: :project_id
  many_to_one :job,     class: "Query",        key: :job_id
  many_to_one :query,   class: "ProjectQuery", key: [:project_id, :query_id]
  unrestrict_primary_key

  def results
    job.results
  end
end
