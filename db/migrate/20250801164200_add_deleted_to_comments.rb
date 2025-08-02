class AddDeletedToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :deleted, :boolean, null: false
  end
end
