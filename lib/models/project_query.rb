require "sequel"
require "models/project"

class ProjectQuery < Sequel::Model
  many_to_one :project, class: "Project", key: :project_id
  plugin :list, scope: :project_id, field: :position
end
