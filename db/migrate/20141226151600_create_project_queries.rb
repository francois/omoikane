Sequel.migration do
  change do
    create_table :project_queries do
      column :project_id, :text, null: false
      column :query_id, :text, null: false, unique: true
      column :title, :text, null: false
      column :sql, :text, null: false

      primary_key [:query_id]
      foreign_key [:project_id], :projects
    end
  end
end
