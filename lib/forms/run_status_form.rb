require "reform"

class RunStatusForm < Reform::Form
  property :run_id
  property :subtitle
  property :submitter
  property :submitted_at
  property :project_id

  def jobs
    model.queries.map(&:job).map{|job| JobForm.new(query: job, state_changes: job.state_changes, results: job.results || QueryResult.new)}
  end

  def project
    model.project
  end

  def project_title
    project.title
  end

  def parameters
    Oj.load(model.parameters)
  end
end
