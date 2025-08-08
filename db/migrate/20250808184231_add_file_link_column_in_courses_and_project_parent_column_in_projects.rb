class AddFileLinkColumnInCoursesAndProjectParentColumnInProjects < ActiveRecord::Migration[8.0]
  def change
    add_reference :projects, :parent_project, foreign_key: { to_table: :projects }, null: true
    add_column :courses, :file_link, :string, null: true
  end
end
