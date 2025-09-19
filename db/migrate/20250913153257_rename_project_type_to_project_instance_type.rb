class RenameProjectTypeToProjectInstanceType < ActiveRecord::Migration[8.0]
  def change
    rename_column :project_instances, :project_type, :project_instance_type
  end
end
