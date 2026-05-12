class DropProjectGroupSlots < ActiveRecord::Migration[8.0]
  def change
    drop_table :project_group_slots
  end
end