class RenameStudentListFinalisedOnCourses < ActiveRecord::Migration[8.0]
  def change
    rename_column :courses, :student_list_finalised, :prevent_leftover_students
  end
end
