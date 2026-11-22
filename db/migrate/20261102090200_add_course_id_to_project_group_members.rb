# A student can be in one group per course. The course is denormalised onto the member so
# the database can enforce it with a unique index.
class AddCourseIdToProjectGroupMembers < ActiveRecord::Migration[8.0]
  def up
    duplicates = select_rows(<<~SQL.squish)
      SELECT g.course_id, m.user_id FROM project_group_members m
      JOIN project_groups g ON g.id = m.project_group_id
      GROUP BY g.course_id, m.user_id HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      pairs = duplicates.map { |course_id, user_id| "course #{course_id} / user #{user_id}" }.join(', ')
      raise "Students in more than one group of a course: #{pairs}. Resolve them by hand, then run this migration again."
    end

    add_reference :project_group_members, :course, type: :integer, foreign_key: true, index: false

    execute <<~SQL.squish
      UPDATE project_group_members SET course_id = g.course_id
      FROM project_groups g WHERE g.id = project_group_members.project_group_id
    SQL

    change_column_null :project_group_members, :course_id, false
    add_index :project_group_members, %i[course_id user_id], unique: true
  end

  def down
    remove_index :project_group_members, %i[course_id user_id]
    remove_reference :project_group_members, :course, foreign_key: true
  end
end
