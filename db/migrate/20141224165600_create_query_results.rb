Sequel.migration do
  change do
    create_table :query_results do
      column :query_id, :text, null: false
      column :results_path, :text
      column :rows_count, :int
      column :columns_count, :int
      column :headers, :text
      column :query_plan, :text
      column :query_errors, :text
      column :created_at, :timestamp, null: false

      primary_key [:query_id]
      foreign_key [:query_id], :queries
    end
  end
end
