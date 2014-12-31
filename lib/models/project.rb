require "sequel"
require "models/project_query"

class Project < Sequel::Model
  one_to_many :queries, class: "ProjectQuery", key: :project_id, order: [:project_id, :title]
  one_to_many :runs,                           key: :project_id, order: [:project_id, :submitted_at]
  unrestrict_primary_key

  def self.most_recent(limit=25)
    Project.order(:title).limit(limit)
  end

  def queries=(qs)
    new_ids      = qs.map(&:query_id)
    existing_ids = queries.map(&:query_id)
    logger.info "Updating multiple queries on project:\nnew_ids: #{new_ids.inspect}\nexisting_ids: #{existing_ids.inspect}"

    (new_ids - existing_ids).each do |id|
      add_query(ProjectQuery.new(qs.detect{|q| q.query_id == id}))
    end

    (existing_ids - new_ids).each do |id|
      queries.detect{|q| q.query_id == id}.delete
    end
  end

  def self.search(query, limit=25)
    grep([:title, :instructions, :notes, :author], ["%#{query}%"], case_insensitive: true).
      order(:title).
      limit(limit).
      all
  end
end
