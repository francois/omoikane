require "csv"

class JobForm < Reform::Form
  include Composition

  property :query_id, on: :query
  property :title,    on: :query
  property :author,   on: :query
  property :sql,      on: :query

  model :query

  property :rows_count,    on: :results
  property :columns_count, on: :results
  property :headers,       on: :results
  property :results_path,  on: :results
  property :query_plan,    on: :results
  property :query_errors,  on: :results
  property :rows,          on: :results

  collection :state_changes, on: :query do
    property :state
    property :updated_at
  end

  def columns
    CSV.parse(headers).first
  end

  def has_results?
    rows_count && rows_count.nonzero?
  end

  def elapsed_seconds
    return 0.0 unless state_changes.any?

    min, max = state_changes.map(&:updated_at).minmax
    if min == max then
      # only one row: submitted but still running
      Time.now.utc - max
    else
      max - min
    end
  end

  def updated_at
    state_changes.map(&:updated_at).max || Time.now.utc
  end

  def finished?
    state_changes.any?{|change| change.state == "finished"}
  end

  def current_state
    state_changes.any? ? state_changes.last.state : nil
  end

  def ran_as_part_of_a_run?
    false
  end
end
