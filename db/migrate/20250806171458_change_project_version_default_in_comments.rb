class ChangeProjectVersionDefaultInComments < ActiveRecord::Migration[8.0]
  def change
    change_column_default :comments, :project_version_number, 1
  end
end
