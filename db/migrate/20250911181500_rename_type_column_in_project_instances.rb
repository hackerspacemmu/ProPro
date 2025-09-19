class RenameTypeColumnInProjectInstances < ActiveRecord::Migration[8.0]
  def change
    rename_column :project_instances, :type, :project_type
  end
end
