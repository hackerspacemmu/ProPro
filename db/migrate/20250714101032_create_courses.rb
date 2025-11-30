class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :course_name, null: false
      t.integer :number_of_updates, null: false
      t.integer :starting_week, null: false
      t.integer :student_access, null: false
      t.boolean :lecturer_access, null: false
      t.boolean :grouped, null: false

      t.timestamps
    end
  end
end
