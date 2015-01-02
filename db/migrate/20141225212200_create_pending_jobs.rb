Sequel.migration do
  change do
    create_table :pending_jobs do
      column :query_id, :text, primary_key: true
      foreign_key [:query_id], :queries
    end
  end
end
