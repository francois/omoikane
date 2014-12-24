Sequel.migration do
  change do
    create_table :queries do
      column :query_id, :text, null: false
      column :author, :text, null: false
      column :title, :text, null: false
      column :sql, :text, null: false

      primary_key [:query_id]
    end
  end
end
