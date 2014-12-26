Sequel.migration do
  change do
    create_table :project_queries do
      column :project_id, :text, null: false
      column :position, :int, null: false
      column :sql, :text, null: false
      column :query_id, :text, null: false, unique: true

      primary_key [:project_id, :position]
      foreign_key [:project_id], :projects
    end
  end
end
