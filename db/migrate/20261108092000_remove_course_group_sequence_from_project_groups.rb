class RemoveCourseGroupSequenceFromProjectGroups < ActiveRecord::Migration[8.0]
  def change
    remove_index :project_groups, column: %i[course_id course_group_sequence]
    remove_column :project_groups, :course_group_sequence, :integer
  end
end
