require "sequel"
require "models/query_state"
require "models/query_result"

class Query < Sequel::Model
  one_to_many :state_changes, class: "QueryState",  key: :query_id
  one_to_one  :results,       class: "QueryResult", key: :query_id
  unrestrict_primary_key
end
