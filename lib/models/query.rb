require "sequel"
require "models/query_state"
require "models/query_result"

class Query < Sequel::Model
  one_to_many :state_changes, class: "QueryState",  key: :query_id, order: :updated_at
  one_to_one  :results,       class: "QueryResult", key: :query_id
  unrestrict_primary_key

  def self.most_recent(limit)
    ds = QueryState.
      select(:query_id, Sequel.as(Sequel.function(:max, :updated_at), :updated_at)).
      group_by(:query_id).
      order(Sequel.function(:max, :updated_at)).
      limit(25)

    join(ds, [:query_id]).
      order(Sequel.desc(:updated_at)).
      all
  end

  def started!
    db.transaction do
      results && results.delete
      self.results = QueryResult.new(created_at: Time.now.utc)
      self.results.save

      add_state_change(QueryState.new(updated_at: Time.now.utc, state: "started"))
    end
  end

  def set_plan!(new_plan)
    db.transaction do
      results.update_fields({query_plan: new_plan}, [:query_plan], raise_on_failure: true)
      add_state_change(QueryState.new(updated_at: Time.now.utc, state: "explained"))
    end
  end

  def set_error!(new_error)
    results.update_fields({query_errors: new_error}, [:query_errors], raise_on_failure: true)
  end

  def set_results!(results_path, rows_count, columns)
    db.transaction do
      add_state_change(QueryState.new(updated_at: Time.now.utc, state: "finished"))
      results.update_fields({
        results_path:  results_path,
        rows_count:    rows_count,
        columns_count: columns.size,
        headers:       columns.to_csv.chomp},
        [:results_path, :rows_count, :columns_count, :headers],
        raise_on_failure: true)
    end
  end

  def failed_explain!
    add_state_change(QueryState.new(updated_at: Time.now.utc, state: "failed_explain"))
  end

  def failed_run!
    add_state_change(QueryState.new(updated_at: Time.now.utc, state: "failed_run"))
  end

  def self.search(query, limit=25)
    ds = QueryState.
      select(:query_id, Sequel.as(Sequel.function(:max, :updated_at), :updated_at)).
      group_by(:query_id).
      order(Sequel.function(:max, :updated_at))

    join(ds, [:query_id]).
      grep([:title, :author, :sql], ["%#{query}%"], case_insensitive: true).
      order(Sequel.desc(:updated_at)).
      limit(limit).
      all
  end
end
