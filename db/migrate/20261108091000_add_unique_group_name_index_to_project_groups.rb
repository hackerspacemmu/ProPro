class AddUniqueGroupNameIndexToProjectGroups < ActiveRecord::Migration[8.0]
  def up
    duplicates = select_rows(<<~SQL.squish)
      SELECT course_id, group_name, COUNT(*) FROM project_groups
      GROUP BY course_id, group_name HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      pairs = duplicates.map { |course_id, group_name, _count| "#{course_id}/#{group_name}" }.join(', ')
      raise "Groups with duplicate names in one course: #{pairs}. Resolve them by hand, then run this migration again."
    end

    add_index :project_groups, %i[course_id group_name], unique: true
  end

  def down
    remove_index :project_groups, %i[course_id group_name]
  end
end
