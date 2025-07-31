class CreateOwnerships < ActiveRecord::Migration[8.0]
  def change
    create_table :ownerships do |t|
      t.references :owner, polymorphic: true, null: false
      t.integer :ownership_type, null: false
      t.timestamps
    end
  end
end
