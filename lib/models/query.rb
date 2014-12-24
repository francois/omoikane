require "sequel"
require "models/query_state"
require "models/query_result"

class Query < Sequel::Model
  one_to_many :state_changes, class: "QueryState",  key: :query_id, order: Sequel.desc(:updated_at)
  one_to_one  :results,       class: "QueryResult", key: :query_id
  unrestrict_primary_key

  def self.most_recent(limit)
    ds = QueryState.
      select(:query_id, Sequel.as(Sequel.function(:max, :updated_at), :updated_at)).
      group_by(:query_id).
      order(Sequel.function(:max, :updated_at)).
      limit(25)

    join(ds, [:query_id]).
      order(:updated_at).
      all
  end
end
