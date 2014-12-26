require "sequel"
require "models/project_query"

class Project < Sequel::Model
  one_to_many :queries, class: "ProjectQuery", key: :project_id, order: [:project_id, :position]
end
