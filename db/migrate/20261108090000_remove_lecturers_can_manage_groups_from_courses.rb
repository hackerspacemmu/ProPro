class RemoveLecturersCanManageGroupsFromCourses < ActiveRecord::Migration[8.0]
  def change
    remove_column :courses, :lecturers_can_manage_groups, :boolean, default: true, null: false
  end
end
