class AddTimestampsToProjectInstance < ActiveRecord::Migration[8.0]
  def change
    add_column :project_instances, :last_status_change_time, :datetime
    add_column :project_instances, :last_edit_time, :datetime
    add_column :project_instances, :last_status_change_by, :integer
    add_column :project_instances, :last_edit_by, :integer
  end
end
