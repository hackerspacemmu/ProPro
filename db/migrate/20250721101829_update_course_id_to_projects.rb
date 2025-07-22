class UpdateCourseIdToProjects < ActiveRecord::Migration[8.0]
  def change
    #add_column :projects, :course_id, :integer, null: false
    add_column :projects, :supervisor_enrolment_id, :integer
    add_foreign_key :projects, :enrolments, column: :supervisor_enrolment_id
    add_index :projects, :supervisor_enrolment_id
  end
end
