class AddGroupingFieldsToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :confirmed, :boolean, default: false, null: false
    add_column :project_groups, :locked, :boolean, default: false, null: false
    add_column :project_groups, :leader_id, :integer
    add_foreign_key :project_groups, :users, column: :leader_id
  end
end