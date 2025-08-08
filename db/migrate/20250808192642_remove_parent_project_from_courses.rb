class RemoveParentProjectFromCourses < ActiveRecord::Migration[8.0]
  def change
    remove_reference :projects, :parent_project
  end
end
