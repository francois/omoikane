Sequel.migration do
  change do
    create_table :pending_jobs do
      column :query_id, :text, primary_key: true
    end
  end
end
