class UpdateProjectsForgeinKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :title, :string, null: false

    rename_column :comments, :proposal_id, :project_id
    rename_column :progress_updates, :proposal_id, :project_id  

    add_foreign_key :progress_updates, :projects
    add_foreign_key :comments, :projects
  end
end
