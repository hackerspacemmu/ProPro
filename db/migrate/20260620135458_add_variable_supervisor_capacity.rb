class AddVariableSupervisorCapacity < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :supervisor_variable_capacity_enabled, :boolean, default: false, null: false
    add_column :courses, :supervisor_auto_calculate_enabled,    :boolean, default: false, null: false

    add_column :enrolments, :supervisor_capacity_offset, :integer, default: 0, null: false
  end
end
