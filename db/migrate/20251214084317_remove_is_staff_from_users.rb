class RemoveIsStaffFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :is_staff, :boolean
  end
end
