require "sequel"
require "models/query"

class QueryResult < Sequel::Model
  one_to_one :query, key: :query_id
end
