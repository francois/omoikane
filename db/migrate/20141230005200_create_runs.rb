Sequel.migration do
  change do
    create_table :runs do
      column :run_id,       :text,      null: false
      column :project_id,   :text,      null: false
      column :subtitle,     :text,      null: false
      column :submitter,    :text,      null: false
      column :submitted_at, :timestamp, null: false
      column :parameters,   :text,      null: false

      primary_key [:run_id]
      foreign_key [:project_id], :projects
    end

    create_table :run_queries do
      column :run_id,     :text, null: false
      column :project_id, :text, null: false
      column :query_id,   :text, null: false
      column :job_id,     :text, null: false

      primary_key [:run_id, :project_id, :query_id]

      foreign_key [:run_id], :runs
      foreign_key [:query_id], :project_queries, key: :query_id
      foreign_key [:job_id], :queries
    end
  end
end
