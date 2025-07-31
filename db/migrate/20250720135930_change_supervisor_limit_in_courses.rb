class ChangeSupervisorLimitInCourses < ActiveRecord::Migration[8.0]
  def change
    rename_column :courses, :supervised_max_underlings, :supervisor_projects_limit
  end
end
