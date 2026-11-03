# One project per group. Partial, because lecturers can own several topics.
class AddUniqueProjectPerGroupIndex < ActiveRecord::Migration[8.0]
  INDEX_NAME = 'index_projects_on_group_owner'.freeze

  def up
    duplicates = select_rows(<<~SQL.squish)
      SELECT owner_id, COUNT(*) FROM projects
      WHERE owner_type = 'ProjectGroup'
      GROUP BY owner_id HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      ids = duplicates.map(&:first).join(', ')
      raise "Groups with more than one project: #{ids}. Resolve them by hand, then run this migration again."
    end

    add_index :projects, :owner_id, unique: true, where: "owner_type = 'ProjectGroup'", name: INDEX_NAME
  end

  def down
    remove_index :projects, name: INDEX_NAME
  end
end
