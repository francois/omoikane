Sequel.migration do
  change do
    create_table :pending do
      column :id, :text, primary_key: true
      foreign_key [:id], :queries
    end
  end
end
