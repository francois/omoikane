require "sequel"
require "models/query"

class QueryState < Sequel::Model
  many_to_one :query, key: :query_id
  unrestrict_primary_key

  def before_save
    self.updated_at = Time.now.utc unless self.updated_at
  end
end
