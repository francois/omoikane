require "sequel"
require "models/project"

class Run < Sequel::Model
  many_to_one :project, key: :project_id
  one_to_many :queries, key: :run_id,    class: "RunQuery", clearer: ->{ queries_dataset.delete }
  unrestrict_primary_key

  def before_create
    self.run_id       ||= UUID.generate
    self.submitted_at ||= Time.now.utc
    super
  end

  def results
    queries.map(&:results)
  end

  def self.most_recent(limit=25)
    order(Sequel.desc(:submitted_at)).
      limit(limit)
  end
end
