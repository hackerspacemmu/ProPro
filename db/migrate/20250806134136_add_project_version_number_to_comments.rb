class AddProjectVersionNumberToComments < ActiveRecord::Migration[8.0]
  def change
     add_column :comments, :project_version_number, :integer, null: false, default: 0
  end
end
