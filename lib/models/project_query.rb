require "sequel"
require "models/project"

class ProjectQuery < Sequel::Model
  many_to_one :project, class: "Project", key: :project_id
  unrestrict_primary_key
end
