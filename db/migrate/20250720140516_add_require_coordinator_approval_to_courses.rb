class AddRequireCoordinatorApprovalToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :require_coordinator_approval, :boolean, null: false
    change_column_null :courses, :supervisor_projects_limit, false
  end
end
