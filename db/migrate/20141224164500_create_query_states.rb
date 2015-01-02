Sequel.migration do
  change do
    create_table :query_states do
      column :query_id, :text, null: false
      column :state, :text, null: false
      column :updated_at, :timestamp, null: false

      primary_key [:query_id, :updated_at]
      foreign_key [:query_id], :queries
    end
  end
end
