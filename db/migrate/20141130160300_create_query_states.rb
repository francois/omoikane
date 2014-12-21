Sequel.migration do
  change do
    create_table :query_states do
      column :id, :text, null: false
      column :updated_at, :timestamp, null: false
      column :state, :text, null: false

      primary_key [:id, :updated_at]
      foreign_key [:id], :queries
    end
  end
end
