class AllowProjectInstanceIdToBeNullInProjectInstanceFields < ActiveRecord::Migration[8.0]
  def change
    change_column_null :project_instance_fields, :project_instance_id, true
  end
end
