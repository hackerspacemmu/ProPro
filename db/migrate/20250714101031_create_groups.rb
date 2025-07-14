class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.string :group_name, null: false
      t.integer :group_role, null: false

      t.timestamps
    end
  end
end
