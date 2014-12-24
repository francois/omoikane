class QueryForm < Reform::Form
  property :title
  property :author
  property :sql

  validates :title, :author, :sql, presence: true

  def persisted?
    model.query_id
  end
end
