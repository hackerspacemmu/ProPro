# No request can be sent until requests reopen, so any pending request is stale.
class DeletePendingJoinRequests < ActiveRecord::Migration[8.0]
  def up
    deleted = execute('DELETE FROM project_group_invites WHERE kind = 0 AND status = 0')
    puts "Deleted #{deleted.cmdtuples} pending join requests."
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
