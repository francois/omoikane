class ProjectQueryForm < Reform::Form
  property :project_id
  property :query_id
  property :title
  property :sql

  validates :title, :sql, presence: true

  def project_title
    model.project.title
  end

  def persisted?
    query_id
  end
end
