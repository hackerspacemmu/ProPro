class RenameUserColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :username, :name
    rename_column :users, :student_id, :instid
  end
end
