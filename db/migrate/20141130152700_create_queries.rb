Sequel.migration do
  change do
    create_table :queries do
      column :id, :text, primary_key: true
      column :author, :text, null: false
      column :title, :text, null: false
      column :submitted_at, :timestamp, null: false
      column :rows_count, :integer
    end
  end
end
