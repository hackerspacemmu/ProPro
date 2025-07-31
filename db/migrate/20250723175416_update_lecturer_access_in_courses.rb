class UpdateLecturerAccessInCourses < ActiveRecord::Migration[8.0]
  def change
    remove_column :courses, :student_access
    remove_column :courses, :lecturer_access

    add_column :courses, :student_access, :integer, null: false
    add_column :courses, :lecturer_access, :boolean, null: false

    change_column_null :courses, :number_of_updates, true
  end
end
