class MoveStatusToProjectInstance < ActiveRecord::Migration[8.0]
  def change
    add_column :project_instances, :status, :integer, null: false, default: 0
    remove_column :projects, :status, :integer
  end
end
