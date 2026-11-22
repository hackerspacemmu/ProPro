class RemoveLockedFromProjectGroups < ActiveRecord::Migration[8.0]
  def change
    remove_column :project_groups, :locked, :boolean, default: false, null: false
  end
end
