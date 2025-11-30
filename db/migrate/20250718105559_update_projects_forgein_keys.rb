class UpdateProjectsForgeinKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :title, :string, null: false
  end
end
