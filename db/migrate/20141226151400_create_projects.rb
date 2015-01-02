Sequel.migration do
  change do
    create_table :projects do
      column :project_id, :text, primary_key: true
      column :title, :text, null: false
      column :author, :text, null: false
      column :instructions, :text, null: false
      column :notes, :text, null: false
    end
  end
end
