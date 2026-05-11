class AddGroupsSequenceToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :course_group_sequence, :integer
    add_index :project_groups, [:course_id, :course_group_sequence], unique: true
  end
end