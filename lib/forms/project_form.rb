require "reform"

class ProjectForm < Reform::Form
  property :project_id
  property :title
  property :author
  property :instructions
  property :notes

  validates :title, :author, :instructions, presence: true

  collection :queries, save: false do
    property :title
    property :sql
    property :query_id
    validates :title, :sql, presence: true
  end

  def persisted?
    project_id
  end
end
