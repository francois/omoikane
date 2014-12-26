class ProjectForm < Reform::Form
  include Composition

  model :project

  property :project_id,   on: :project
  property :title,        on: :project
  property :author,       on: :project
  property :instructions, on: :project
  property :notes,        on: :project

  validates :title, :author, :instructions, :notes, presence: true

  collection :queries, on: :project do
    property :title
    property :position
    property :sql
    property :query_id
    validates :title, :position, :sql, presence: true
  end

  def persisted?
    project_id
  end
end
