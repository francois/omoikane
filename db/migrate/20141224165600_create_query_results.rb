Sequel.migration do
  change do
    create_table :query_results do
      column :query_id, :text, null: false
      column :results_path, :text, null: false
      column :rows_count, :int, null: false
      column :columns_count, :int, null: false
      column :headers, :text, null: false
      column :plan, :text, null: false
      column :errors, :text, null: false
      column :created_at, :timestamp, null: false

      primary_key [:query_id]
      foreign_key [:query_id], :queries
    end
  end
end
