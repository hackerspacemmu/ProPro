class RemoveOwnershipsAndCommentsColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :ownership_id
    remove_column :comments, :project_id
    remove_column :comments, :project_version_number
  end
end
