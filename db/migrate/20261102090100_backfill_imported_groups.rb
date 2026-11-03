# CSV imports used to create unconfirmed groups without a leader, which blocked project creation.
# Confirms those groups only where grouping is off (nobody else could confirm them), then gives
# every leaderless group its earliest member as leader. Step 1 reads "no leader", so it runs first.
class BackfillImportedGroups < ActiveRecord::Migration[8.0]
  def up
    step1 = execute <<~SQL.squish
      UPDATE project_groups SET confirmed = #{quoted_true}
      WHERE confirmed = #{quoted_false}
        AND leader_id IS NULL
        AND course_group_sequence IS NULL
        AND course_id IN (SELECT id FROM courses WHERE grouping_enabled = #{quoted_false})
    SQL

    step2 = execute <<~SQL.squish
      UPDATE project_groups SET confirmed = #{quoted_true}
      WHERE confirmed = #{quoted_false}
        AND EXISTS (SELECT 1 FROM projects WHERE owner_type = 'ProjectGroup' AND owner_id = project_groups.id)
    SQL

    step3 = execute <<~SQL.squish
      UPDATE project_groups
      SET leader_id = (
        SELECT m.user_id FROM project_group_members m
        WHERE m.project_group_id = project_groups.id
        ORDER BY m.created_at, m.id LIMIT 1
      )
      WHERE leader_id IS NULL
        AND EXISTS (SELECT 1 FROM project_group_members m WHERE m.project_group_id = project_groups.id)
    SQL

    puts "Confirmed #{step1.cmdtuples} imported groups and #{step2.cmdtuples} groups that already have a project; assigned a leader to #{step3.cmdtuples} groups."
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def quoted_true = connection.quoted_true
  def quoted_false = connection.quoted_false
end
