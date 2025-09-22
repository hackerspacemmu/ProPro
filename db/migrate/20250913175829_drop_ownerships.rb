class DropOwnerships < ActiveRecord::Migration[8.0]
  def change
    drop_table :ownerships
  end
end
