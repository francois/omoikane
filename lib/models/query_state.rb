require "sequel"
require "models/query"

class QueryState < Sequel::Model
  many_to_one :query, key: :query_id
  unrestrict_primary_key
end
