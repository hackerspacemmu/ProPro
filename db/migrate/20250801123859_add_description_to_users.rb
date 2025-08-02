class AddDescriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :description, :string, null: true
    rename_column :users, :mmu_directory, :web_link
  end
end
