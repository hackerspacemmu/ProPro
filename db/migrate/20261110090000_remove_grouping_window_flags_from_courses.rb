# Drops the grouping window flags now derived from the enable switch and end date.
class RemoveGroupingWindowFlagsFromCourses < ActiveRecord::Migration[8.0]
  def change
    change_table :courses, bulk: true do |t|
      t.remove :grouping_open, type: :boolean
      t.remove :grouping_opens_at, type: :datetime
    end
  end
end
