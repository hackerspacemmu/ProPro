class AddDeletableInComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :deletable, :boolean, null: false, default: true
  end
end
