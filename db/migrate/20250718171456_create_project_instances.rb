class CreateProjectInstances < ActiveRecord::Migration[8.0]
  def change
    create_table :project_instances do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :version, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime   :submitted_at

      t.timestamps
    end
    remove_column :projects, :proposal, :string
    remove_column :projects, :title, :string
    add_index :project_instances, [:project_id, :version], unique: true
  end
end
