class AddStatusBackToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :status, :integer, null: false, default: 0
    remove_column :comments, :deletable, :boolean
  end
end
