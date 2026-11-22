class RenameGroupingColumnsOnCourses < ActiveRecord::Migration[8.0]
  def change
    rename_column :courses, :grouping_enabled, :group_formation_enabled
    rename_column :courses, :grouping_closes_at, :group_formation_closes_at
  end
end
