class AddGroupingSettingsToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :grouping_enabled, :boolean, default: false, null: false
    add_column :courses, :student_list_finalised, :boolean, default: false, null: false
    add_column :courses, :group_min, :integer
    add_column :courses, :group_max, :integer
    add_column :courses, :grouping_opens_at, :datetime
    add_column :courses, :grouping_closes_at, :datetime
  end
end