class AddCourseDescripionToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :course_description, :string, null: true
  end
end
